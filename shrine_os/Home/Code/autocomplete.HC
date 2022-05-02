//Basic autocomplete using a Trie
//The trie is really not efficient
//The words should be supplied in a dict.txt file.

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct n {
	struct n *subtrie[26];
	int isEnd;
} trie;

void insert(trie *ele, char *word) {

	trie *root = ele;

	int len = strlen(word);

	for (int i = 0; i < len; i++) {

		trie *curr = ele->subtrie[word[i] % 97];

		if (curr == NULL) {
			curr = malloc (sizeof (trie));
			curr->isEnd = 0;
			for(int i = 0; i < 26; i++) curr->subtrie[i] = NULL;
		}

		if(i + 1 == len) curr->isEnd = 1;

		ele->subtrie[word[i] % 97] = curr;
		ele = ele->subtrie[word[i] % 97];
	}

	ele = root;
}

char *append (char *slice, char part) {

	char *str = malloc (sizeof (char) * (strlen (slice) + 2));

	int i = 0;
	while (slice[i] != '\0') str[i] = slice[i++];

	str[i++] = part;
	str[i] = '\0';

	return str;
}

void print(trie *ele, char *slice) {

	if (ele == NULL) return;

	if (ele->isEnd) printf("%s\n", slice);

	for (int i = 0; i < 26; i++)
		if(ele->subtrie[i] != NULL)
			print (ele->subtrie[i], append (slice, i + 97));
}

void autocomplete(trie *ele, char *prefix) {

	int len = strlen (prefix);
	for (int i = 0; i < len; i++) ele = ele->subtrie[prefix[i] % 97];

	print (ele, prefix);
}

int main() {

	trie n;
	n.isEnd = 0;
	for (int i = 0; i < 26; i++) n.subtrie[i] = NULL;

	FILE *fp = fopen ("dict.txt", "r");

	char str[25];

	while (!feof (fp)) {
		fscanf (fp, "%s", str);
		insert (&n, str);
	}

	fclose (fp);

	char input[100];

	while (1) {
		printf (">> ");
		scanf ("%s", input);
		autocomplete (&n, input);
	}

	return 0;
}