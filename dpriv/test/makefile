# Copyright (C) 2007, 2008 Andy Spencer <spenceal@rose-hulman.edu>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

default: test.bin Test.class

test: test.bin test.ss Test.class
	@rm  -f /tmp/dpriv-*
	(./test.bin; java Test; mzscheme -r test.ss; true )
	@echo "Files created:"
	@ls -1 /tmp/dpriv-*
	@rm  -f /tmp/dpriv-*
	( dpriv ./test.bin; dpriv java Test; dpriv mzscheme -r test.ss; true )
	@echo "Files created:"
	@( ls -1 /tmp/dpriv-*; true )

test.bin: test.c
	gcc -o $@ $<

Test.class: Test.java
	javac Test.java

clean:
	rm -f *.class test.bin
