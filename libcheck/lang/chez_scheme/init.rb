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

class ChezSchemeGrader < Grader
    def initialize(testcases, student_code, library=nil)
        super(testcases, student_code, library)
        require 'pathname'
        require 'ftools'
        chez_dir = Pathname.new(File.dirname(__FILE__)+"/chez-init").realpath
        Dir.glob("#{chez_dir}/*.ss").each {|e|
            begin
                File.symlink(e, File.dirname(student_code) +
                                "/" + File.basename(e))
            rescue
            end
        }
        @checker_path = Pathname.new(File.dirname(__FILE__) + 
                                     "/checker.ss").realpath.to_s
        @cmper_path = Pathname.new(File.dirname(__FILE__) + 
                                   "/cmper.ss").realpath.to_s
    end

    def checker_cmd(test_dir, test_main, lib_dir, lib_main)
        {:init => proc { Dir.chdir(test_dir) },
         :cmd  => ['petite', '--script', @checker_path, test_main] + 
#        :cmd  => ['scheme', '--script', @checker_path, test_main] +
                   (lib_main == "" ? [] : [lib_dir + "/" + lib_main])}
    end

    def cmper_cmd(lib_dir=".", lib_main="")
        {:init => proc { Dir.chdir(lib_dir) },
         :cmd  => ['petite', '--script', @cmper_path] + 
#        :cmd  => ['scheme', '--script', @cmper_path] + 
                  (lib_main == "" ? [] : [lib_main])}
    end
end
