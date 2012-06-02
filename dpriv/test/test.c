#include <stdio.h>

int main() {
	fprintf(stdout, "Hello World, from C!\n");
	fflush(stdout);
	FILE *fd = fopen("/tmp/dpriv-c-test", "w+");
	if (fd == NULL) return 0;
	fprintf(fd, "Hello World, from C!\n");
	return 0;
}
