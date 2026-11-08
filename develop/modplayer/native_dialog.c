#include "native_dialog.h"
#include <gtk/gtk.h>
#include <string.h>
#include <stdio.h>
#include <unistd.h>
#include <limits.h>

static int gtk_ready = 0;
/* Set to 1 while a dialog is running. nd_pump() is a no-op during that,
   so the caller's SDL loop can't re-enter GTK's event pump from inside
   gtk_dialog_run's own loop (which corrupts the file chooser). */
static int dialog_running = 0;

int nd_init(void) {
    if (gtk_ready) return 1;
    if (!gtk_init_check(NULL, NULL)) {
        fprintf(stderr, "native_dialog: gtk_init_check failed (no display?)\n");
        return 0;
    }
    gtk_ready = 1;
    return 1;
}

void nd_pump(void) {
    if (!gtk_ready) return;
    if (dialog_running) return;      /* don't re-enter while a dialog is open */
    while (gtk_events_pending())
        gtk_main_iteration_do(FALSE);
}

static char last_dir[PATH_MAX] = "";

static void seed_last_dir(void) {
    if (last_dir[0]) return;
    if (!getcwd(last_dir, sizeof(last_dir))) last_dir[0] = '\0';
}

static void remember_from_path(const char *path, int is_dir) {
    if (!path || !path[0]) return;
    if (is_dir) {
        snprintf(last_dir, sizeof(last_dir), "%s", path);
        return;
    }
    const char *slash = strrchr(path, '/');
    if (!slash) return;
    size_t n = (size_t)(slash - path);
    if (n == 0) n = 1;
    if (n >= sizeof(last_dir)) n = sizeof(last_dir) - 1;
    memcpy(last_dir, path, n);
    last_dir[n] = '\0';
}

/* Local event pump used only by the dialog helpers below. Runs a full
   gtk_main_iteration loop to completion, but only from the dialog's own
   call stack — never from main's per-frame nd_pump(). */
static void drain_gtk_events(void) {
    while (gtk_events_pending())
        gtk_main_iteration_do(FALSE);
}

static void add_module_filters(GtkFileChooser *fc) {
    static const char *pats[] = {
        "*.mod", "*.xm", "*.s3m", "*.it", "*.mptm", "*.umx",
        "*.mtm", "*.669", "*.med", "*.stm", "*.okt", "*.far",
        "*.mdl", "*.ult",
        "*.mp3", "*.mp2", "*.mp1", "*.aac", "*.ac3", "*.eac3",
        "*.dts", "*.m4a", "*.ogg", "*.oga", "*.opus", "*.wma",
        "*.mpc", "*.au", "*.thd",
        "*.flac", "*.wav", "*.aiff", "*.ape", "*.wv", "*.tta",
        "*.tak", "*.dsf", "*.dff",
        "*.mka",
        NULL
    };
    GtkFileFilter *mods = gtk_file_filter_new();
    gtk_file_filter_set_name(mods, "Audio (modules + libmpv)");
    for (int i = 0; pats[i]; i++) gtk_file_filter_add_pattern(mods, pats[i]);
    gtk_file_chooser_add_filter(fc, mods);

    GtkFileFilter *all = gtk_file_filter_new();
    gtk_file_filter_set_name(all, "All files");
    gtk_file_filter_add_pattern(all, "*");
    gtk_file_chooser_add_filter(fc, all);
}

static void apply_initial_folder(GtkFileChooser *fc) {
    seed_last_dir();
    if (last_dir[0]) gtk_file_chooser_set_current_folder(fc, last_dir);
}

int nd_pick_module_file(char *out_path, size_t out_sz) {
    if (!out_path || out_sz == 0) return 0;
    out_path[0] = '\0';
    if (!nd_init()) return 0;

    GtkWidget *d = gtk_file_chooser_dialog_new(
        "Load Module", NULL,
        GTK_FILE_CHOOSER_ACTION_OPEN,
        "_Cancel", GTK_RESPONSE_CANCEL,
        "_Open",   GTK_RESPONSE_ACCEPT,
        NULL);
    GtkFileChooser *fc = GTK_FILE_CHOOSER(d);
    add_module_filters(fc);
    apply_initial_folder(fc);

    gtk_window_set_modal(GTK_WINDOW(d), TRUE);
    gtk_window_set_keep_above(GTK_WINDOW(d), TRUE);
    gtk_widget_show_all(d);

    dialog_running = 1;
    char *picked = NULL;
    if (gtk_dialog_run(GTK_DIALOG(d)) == GTK_RESPONSE_ACCEPT)
        picked = gtk_file_chooser_get_filename(fc);

    /* Grab the string BEFORE destroying the dialog. */
    int ok = 0;
    if (picked) {
        snprintf(out_path, out_sz, "%s", picked);
        remember_from_path(picked, 0);
        g_free(picked);
        ok = 1;
    }

    gtk_widget_destroy(d);
    drain_gtk_events();
    dialog_running = 0;
    return ok;
}

int nd_pick_folder(char *out_path, size_t out_sz) {
    if (!out_path || out_sz == 0) return 0;
    out_path[0] = '\0';
    if (!nd_init()) return 0;

    GtkWidget *d = gtk_file_chooser_dialog_new(
        "Add Folder (recursive)", NULL,
        GTK_FILE_CHOOSER_ACTION_SELECT_FOLDER,
        "_Cancel", GTK_RESPONSE_CANCEL,
        "_Add",    GTK_RESPONSE_ACCEPT,
        NULL);
    GtkFileChooser *fc = GTK_FILE_CHOOSER(d);
    add_module_filters(fc);
    apply_initial_folder(fc);

    gtk_window_set_modal(GTK_WINDOW(d), TRUE);
    gtk_window_set_keep_above(GTK_WINDOW(d), TRUE);
    gtk_widget_show_all(d);

    dialog_running = 1;
    char *picked = NULL;
    if (gtk_dialog_run(GTK_DIALOG(d)) == GTK_RESPONSE_ACCEPT)
        picked = gtk_file_chooser_get_filename(fc);

    int ok = 0;
    if (picked) {
        snprintf(out_path, out_sz, "%s", picked);
        remember_from_path(picked, 1);
        g_free(picked);
        ok = 1;
    }

    gtk_widget_destroy(d);
    drain_gtk_events();
    dialog_running = 0;
    return ok;
}

int nd_pick_module_files(char *out_paths, size_t out_sz,
                         int *out_count, int max_files) {
    if (out_count) *out_count = 0;
    if (!out_paths || out_sz == 0) return 0;
    out_paths[0] = '\0';
    if (!nd_init()) return 0;

    GtkWidget *d = gtk_file_chooser_dialog_new(
        "Add Files", NULL,
        GTK_FILE_CHOOSER_ACTION_OPEN,
        "_Cancel", GTK_RESPONSE_CANCEL,
        "_Add",    GTK_RESPONSE_ACCEPT,
        NULL);
    GtkFileChooser *fc = GTK_FILE_CHOOSER(d);
    gtk_file_chooser_set_select_multiple(fc, TRUE);
    add_module_filters(fc);
    apply_initial_folder(fc);

    gtk_window_set_modal(GTK_WINDOW(d), TRUE);
    gtk_window_set_keep_above(GTK_WINDOW(d), TRUE);
    gtk_widget_show_all(d);

    dialog_running = 1;
    GSList *files = NULL;
    if (gtk_dialog_run(GTK_DIALOG(d)) == GTK_RESPONSE_ACCEPT)
        files = gtk_file_chooser_get_filenames(fc);

    gtk_widget_destroy(d);
    drain_gtk_events();
    dialog_running = 0;

    int count = 0;
    char first[PATH_MAX] = "";
    for (GSList *l = files; l && count < max_files; l = l->next) {
        size_t used = strlen(out_paths);
        size_t need = strlen((char *)l->data) + 2;
        if (used + need >= out_sz) { g_free(l->data); continue; }
        if (count) strcat(out_paths, "\n");
        strcat(out_paths, (char *)l->data);
        if (count == 0) snprintf(first, sizeof(first), "%s", (char *)l->data);
        g_free(l->data);
        count++;
    }
    if (files) g_slist_free(files);

    if (first[0]) remember_from_path(first, 0);
    if (out_count) *out_count = count;
    return count > 0;
}
