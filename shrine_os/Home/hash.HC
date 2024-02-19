#define cmd_cnt 33
#define HASH_TABLE_SIZE 256 // Increased size of the hash table

U8 *cmds[cmd_cnt] = {
  "cat","cd","cdd","clear","cp","cpu","date","df","dump","ed",
  "exit","fm","grep","help","ls","man","mem","mkdir","more","mv",
  "now","quit","rd","rm","rmdir","run","tasks","term","time","touch",
  "tree","view","vol"
};

U64 hash_for(U8 *what)
{//Generates a hash for a string and returns an array index
  U64 hash = 0;

  while (*what) hash+=*what++;

  return hash % HASH_TABLE_SIZE;
}

//"hash_for %s:%d\n","ls",hash_for("ls");

U64 i=0;

for(;i<cmd_cnt;i++)
{
  "hash_for%6s: %3d\n",cmds[i],hash_for(cmds[i]);
}

/*
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define HASH_TABLE_SIZE 256

unsigned int arc_compress(const char *input) {
    unsigned int hash = 0;
    while (*input) {
        hash += *input++;
    }
    return hash;
}

int hash_to_index(unsigned int hash) {
    return hash % HASH_TABLE_SIZE;
}

int main() {
    const char *strings[] = {"view", "man", "date", "ls", "mv", "tasks", "cd", "cpu", "ed", "df", "cdd",
                             "grep", "time", "tree", "vol", "cp", "now", "run", "rd", "mkdir", "cat",
                             "rmdir", "mem", "rm", "quit", "touch", "clear", "help", "fm", "more", "dump",
                             "term"};
    int num_strings = sizeof(strings) / sizeof(strings[0]);

    const char *hash_table[HASH_TABLE_SIZE] = {NULL};

    for (int i = 0; i < num_strings; i++) {
        unsigned int hash = arc_compress(strings[i]);
        int index = hash_to_index(hash);
//        while (hash_table[index] != NULL) {
//            index = (index + 1) % HASH_TABLE_SIZE;
//        }
        hash_table[index] = strings[i];
    }

    printf("Hashes and their corresponding indexes (sorted by index):\n");
    for (int i = 0; i < HASH_TABLE_SIZE; i++) {
        if (hash_table[i] != NULL) {
            printf("Index: %d - String: %s\n", i, hash_table[i]);
        }
    }

    return 0;
}
*/