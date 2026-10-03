/* gcc -std=c11 -O2 -Wall -Wextra \
    m4vplay.c \
    $(pkg-config --cflags --libs sdl2 mpv) \
    -o m4vplay
*/

#include <stdio.h>
#include <stdlib.h>

#include <SDL2/SDL.h>

#include <mpv/client.h>
#include <mpv/render.h>
#include <mpv/render_gl.h>

static void die(const char *msg)
{
    fprintf(stderr, "Error: %s\n", msg);
    exit(EXIT_FAILURE);
}


static void *get_proc_address(
    void *ctx,
    const char *name)
{
    (void)ctx;
    return SDL_GL_GetProcAddress(name);
}


int main(int argc, char **argv)
{
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <video-file>\n", argv[0]);
        return EXIT_FAILURE;
    }

    if (SDL_Init(SDL_INIT_VIDEO) != 0)
        die(SDL_GetError());

    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 2);
    SDL_GL_SetAttribute(
        SDL_GL_CONTEXT_PROFILE_MASK,
        SDL_GL_CONTEXT_PROFILE_CORE
    );

    SDL_Window *window = SDL_CreateWindow(
        "m4vplay",
        SDL_WINDOWPOS_CENTERED,
        SDL_WINDOWPOS_CENTERED,
        1280,
        720,
        SDL_WINDOW_OPENGL |
        SDL_WINDOW_RESIZABLE
    );

    if (!window)
        die(SDL_GetError());

    SDL_GLContext gl_context =
        SDL_GL_CreateContext(window);

    if (!gl_context)
        die(SDL_GetError());

    SDL_GL_MakeCurrent(window, gl_context);
    SDL_GL_SetSwapInterval(1);

    // libmpv
    mpv_handle *mpv = mpv_create();

    if (!mpv)
        die("mpv_create() failed");

    if (mpv_set_option_string(
            mpv,
            "vo",
            "libmpv") < 0)
        die("could not set vo=libmpv");

    if (mpv_set_option_string(
            mpv,
            "terminal",
            "no") < 0)
        die("could not disable terminal output");

    if (mpv_initialize(mpv) < 0)
        die("mpv_initialize() failed");


    // libmpv OpenGL renderer
    mpv_opengl_init_params gl_init_params = {
        .get_proc_address = get_proc_address,
        .get_proc_address_ctx = NULL
    };

    mpv_render_param render_params[] = {
        {
            MPV_RENDER_PARAM_API_TYPE,
            MPV_RENDER_API_TYPE_OPENGL
        },
        {
            MPV_RENDER_PARAM_OPENGL_INIT_PARAMS,
            &gl_init_params
        },
        { 0 }
    };

    mpv_render_context *mpv_gl = NULL;

    int rc = mpv_render_context_create(
        &mpv_gl,
        mpv,
        render_params
    );

    if (rc < 0) {
        fprintf(
            stderr,
            "mpv_render_context_create failed: %s\n",
            mpv_error_string(rc)
        );
        return EXIT_FAILURE;
    }


     // Load
    const char *cmd[] = {
        "loadfile",
        argv[1],
        NULL
    };

    rc = mpv_command(mpv, cmd);

    if (rc < 0) {
        fprintf(
            stderr,
            "Could not load file: %s\n",
            mpv_error_string(rc)
        );
        return EXIT_FAILURE;
    }

    int running = 1;

    while (running) {

        SDL_Event event;

        while (SDL_PollEvent(&event)) {

            if (event.type == SDL_QUIT) {
                running = 0;
            }

            if (event.type == SDL_KEYDOWN &&
                event.key.keysym.sym == SDLK_ESCAPE) {
                running = 0;
            }
        }


       // mpv events
        while (1) {

            mpv_event *event =
                mpv_wait_event(mpv, 0);

            if (event->event_id == MPV_EVENT_NONE)
                break;

            if (event->event_id == MPV_EVENT_END_FILE) {
                running = 0;
                break;
            }
        }

        int width;
        int height;

        SDL_GetWindowSize(
            window,
            &width,
            &height
        );

        mpv_opengl_fbo fbo = {
            .fbo = 0,
            .w = width,
            .h = height,
            .internal_format = 0
        };

        int flip_y = 1;

        mpv_render_param params[] = {
            {
                MPV_RENDER_PARAM_OPENGL_FBO,
                &fbo
            },
            {
                MPV_RENDER_PARAM_FLIP_Y,
                &flip_y
            },
            { 0 }
        };

        rc = mpv_render_context_render(
            mpv_gl,
            params
        );

        if (rc < 0) {
            fprintf(
                stderr,
                "mpv_render_context_render: %s\n",
                mpv_error_string(rc)
            );
        }

        SDL_GL_SwapWindow(window);

        SDL_Delay(10);
    }

    mpv_render_context_free(mpv_gl);

    mpv_destroy(mpv);

    SDL_GL_DeleteContext(gl_context);
    SDL_DestroyWindow(window);

    SDL_Quit();

    return EXIT_SUCCESS;
}
