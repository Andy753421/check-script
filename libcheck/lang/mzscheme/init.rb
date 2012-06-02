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

class MzSchemeGrader < Grader
	def initialize(*args)
		super(*args)
		require 'pathname'
		@checker_path = Pathname.new(File.dirname(__FILE__)+"/checker.ss").realpath
		@cmper_path   = Pathname.new(File.dirname(__FILE__)+"/cmper.ss").realpath
	end
	def checker_cmd(test_dir, test_main)
		{:init => proc { Dir.chdir(test_dir) },
		 :cmd  => ['mzscheme', '-r', @checker_path, test_main]}
	end
	def cmper_cmd(lib_dir, lib_main)
		lib_main_args = ['', '.'].include?(lib_main) ? [] : ["-f", lib_main]
		{:init => proc { Dir.chdir(lib_dir) },
		 :cmd  => ['mzscheme'] + lib_main_args + ['-r', @cmper_path]}
	end
end
