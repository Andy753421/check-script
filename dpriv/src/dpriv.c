/*
Copyright (C) 2007, 2008 Andy Spencer <spenceal@rose-hulman.edu>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

(not really sure if there's enough here to copyright though..)
*/

#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>

int main(int argc, char **argv) {
	if (argc < 2) {
		printf("usage: %s <command> [argument]...\n", argv[0]);
		exit(EINVAL);
	}
	execvp(argv[1], argv+1);
}
