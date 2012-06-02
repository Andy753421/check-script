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

class IO
	def wipe
		string = ""
		begin
			while true
				string += self.read_nonblock(4096)
			end
		rescue
		end
		return string
	end
end

class PIO
	attr_reader :stdin, :stdout, :stderr, :pid

	def initialize(*cmd)
		stdin  = IO::pipe   # pipe[0] for read, pipe[1] for write
		stdout = IO::pipe
		stderr = IO::pipe
        
    	@pid = fork {
	    	if block_given?
		   		yield
		    end
		    #pp cmd

		    stdin[1].close
		    STDIN.reopen(stdin[0])
		    stdin[0].close

		    stdout[0].close
		    STDOUT.reopen(stdout[1])
		    stdout[1].close

		    stderr[0].close
		    STDERR.reopen(stderr[1])
		    stderr[1].close

		    exec(*cmd)
	    }
		stdin[0].close
		stdout[1].close
		stderr[1].close

		stdin[1].sync = true

		@stdin  = stdin[1]
		@stdout = stdout[0]
		@stderr = stderr[0]
	end

    def kill(signal=:TERM)
		@stdin.close
		@stdout.close
		@stderr.close
		Process.kill(signal, @pid)
        Process.wait(@pid) # This waits for the process to die effectively
	end
end

if $0 == __FILE__
	pio = PIO.new("cat")
	Thread.start do
		while line = gets
			pio.stdin.print line
		end
		pio.stdin.close
	end
	while line = pio.stdout.gets
		print ":", line
	end
end 
