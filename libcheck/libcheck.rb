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

require 'pp'
require 'tempfile'

# Fields
# maxtime_total
# maxtime_each
# library
# test_code
# comparator
# expected

# Example testcase:
# plugin = {
#   
# }
# run = {
#   :checker_cmd => "cd #{student_code} && dpriv mzscheme -r #{checker_path} main.ss"
#   :cmper_cmd   => "dpriv mzscheme -f #{library} -r #{cmper_path}"
#   :testcases   => [<testcase>, ..]
# }
# group = {
#   { # Union 
#       # Groups
#       :maxtime_total   => 10, # Currently ignored
#       :defaults => {
#           :maxtime    => 5,
#           :comparator => 5,
#       }
#       :testecases      => [<testcase>, ...],
#   } || {
#       # Testcases
#       :maxtime    => 3,
#       :test_code  => "(fact 6)",
#       :comparator => "equal?",
#       :expected   => "720",
#   }
# }
# output = input merged with {
#   :status => :success,
#   :actual => "720",
#   :errors => "720",
# }
class Checker
    attr_accessor :testcases, :checker_cmd, :cmper_cmd, :logger
    def initialize(checker_cmd, cmper_cmd, testcases)
        @checker_cmd = checker_cmd
        @cmper_cmd   = cmper_cmd
        @testcases   = testcases
    end

    def debug(message)
        if (@logger)
            logger.debug message
        else
            puts message
        end
    end

    # Spawn/Respawn the checker and comparator processes. 
    # This need to be set to the global variables @cmper and @checker
    # Passing these though as arguments doesn't work because they need to be 
    # reset globally when errors occur.
    def start_proc(name)
        load File.dirname(__FILE__) + "/pio.rb"
        cmd = self.instance_variable_get("@#{name}_cmd")

        self.debug "DEBUG:   running [#{cmd[:cmd].join(' ')}]"
        begin
            process = PIO.new(*(['dpriv']+cmd[:cmd]), &cmd[:init])
        rescue 
            # NOTE: We need to find some way to check whether or not the 
            # code loaded correctly - we're kicking off the checker and the 
            # comparator as separate processes, but interaction with them 
            # is somewhat limited...
            self.debug "DEBUG:   failed to load file"
            return false
        end

        #if $? != 0
        #    puts "Failed to load code..."
        #else
        #    puts "Code appears to have loaded properly..."
        #end

        self.instance_variable_set("@#{name}", process)
        return true
    end
   
    def stop_proc(name)
        process = self.instance_variable_get("@#{name}")
        self.debug "DEBUG:   killing [#{process.pid}]"
        process.kill
    end

    def restart_proc(name)
        self.debug "DEBUG: respawning #{name}"
        stop_proc(name)
        start_proc(name)
        self.debug "DEBUG: respawn finished"
    end

    # Set up and recursivly check an assignment
    def run()
        # See also, respawn
        if (not start_proc(:checker))
            self.debug "DEBUG:   Failed to start checker process"
            return nil
        end
        if (not start_proc(:cmper))
            self.debug "DEBUG:   Failed to start comparator process"
            return nil
        end

        run_tests(@testcases)
        puts "Done testing, trying to stop processes"
        stop_proc(:checker)
        stop_proc(:cmper)
        puts "Done stopping processes"

        return @testcases
    end

    # Check all the problems and test cases in an assignment
    # Modifies the given set of testcases to contain the testcase output
    def run_tests(current, parent_defaults={})
        if (current[:testcases])
            # It's a group of testcases
            new_defaults = parent_defaults.merge(current[:defaults] || {})
            current[:testcases].each {|tc|
                run_tests(tc, new_defaults)
            }
        else
            # It's a testcase
            tc = current.merge(parent_defaults)
            run_testcase(tc)
            current[:status] = tc[:status]
            current[:actual] = tc[:actual]
            current[:errors] = tc[:errors]
        end
    end

    # Do all the dirty work for checking a test case
    # This handles things like watching for timeouts, and errors.
    # Relies on having @checker and @cmper started, but will restart them when
    # errors occur
    # tc starts as {
    #   :maxtime    => 3,
    #   :test_code  => "(fact 6)",
    #   :comparator => "equal?",
    #   :expected   => "720",
    # } and gets {
    #   :status   => :success,
    #   :actual   => "720",
    # } added.
    # \return [expected?, response/error] for the test case
    def run_testcase(tc)
        puts "starting ctc" ###
        status = actual = errors = cmp_status = nil
        # Run the code in a separate thread so that we can watch for timeouts
        # and kill them in order to prevent infinite loops and such.
        thread = Thread.new {
            puts "Started thread #{Thread.current}" ###
            begin
                @checker.stdin.puts(tc[:test_code])
                @checker.stdin.flush
                self.debug "checker << " + tc[:test_code]
                puts "checker << " + tc[:test_code]
                # Figure out why this doesn't raise 'Broken Pipe' on
                # syntax errors in the students code

                # Get the students response. Raise an error when we encounter 
                # an EOF (would most likely be caused by a error in the
                # students code that causes the checker to exit prematurely).
                actual = "#{@checker.stdout.gets}#{@checker.stdout.wipe}"
                if (actual == nil)
                    errors = @checker.stderr.wipe.strip
                    status = :checker_error
                    break 
                end

                actual.strip!
                self.debug "checker >> [" + actual + "]"
                puts "checker >> [" + actual + "]"

                # Write the expected answer and the student's to the
                # comparator, replace newlines with whitespace
                @cmper.stdin.puts(tc[:comparator].gsub(/\n/, ' '))
                @cmper.stdin.puts(tc[:expected  ].gsub(/\n/, ' '))
                @cmper.stdin.puts(actual.gsub(/\n/, ' '))
                self.debug "cmper << " + tc[:comparator].gsub(/\n/, ' ')
                self.debug "cmper << " + tc[:expected  ].gsub(/\n/, ' ')
                self.debug "cmper << " + actual.gsub(/\n/, ' ')

                # Get the comparators response. Raise an error on EOF, this 
                # shouldn't happen and would be cause by an error in the 
                # comparator.
                cmp_status = "#{@cmper.stdout.gets}#{@cmper.stdout.wipe}"
                if (cmp_status == nil)
                    errors = @cmper.stderr.wipe.strip
                    status = :cmper_error
                    break
                end

                cmp_status.strip!
                self.debug "cmper >> [" + cmp_status + "]"

                # Catch misc errors
            rescue => e1
                errors = @cmper.stderr.wipe.strip
                status = :misc_error
                pp e1.backtrace
                actual = actual || ""
                errors = "#{errors || ""}#{e1}"
            end
        }
        # Wait for the timeout
#        if tc[:maxtime] < 100
#            # Assuming that the timeout was specified in seconds, so we 
#            # don't need to convert anything
#            wait_time = tc[:maxtime]
#        else
#            # If the maxtime is sufficiently large, we're going to assume 
#            # that it's specified in milliseconds, therefore we need to 
#            # convert it to seconds
        wait_time = tc[:maxtime] / 1000.0
#        end

        self.debug "DEBUG: Joining on #{wait_time} seconds"
        tmp = thread.join(wait_time)
        if tmp == nil
            errors = "Timed out"
            status = :code_timeout
        end

        # Clean up and restart procs as needed
        if (status == :code_timeout || status == :misc_error)
            thread.kill!
            restart_proc(:checker)
            restart_proc(:cmper)
        elsif (status == :checker_error)
            restart_proc(:checker)
        elsif (status == :cmper_error)
            restart_proc(:checker)
        else
            # Execution ok, check status of cmper
            status = (cmp_status == 'true' ? :success : :fail)
            # store errors just in case..
            errors = @checker.stderr.wipe.strip
        end
        
        self.debug "DEBUG: #{status}"
        puts "Status: #{status}"

        if (status != :success)
            # This will restart the checker whenever a testcase fails for 
            # any reason (wrong answer, timeout, etc.)
            # TODO: This should be changed so that the checker doesn't get 
            # restarted if the checker is still when the student returns an 
            # incorrect answer
            restart_proc(:checker)
        end
        tc[:status] = status
        tc[:actual] = actual
        tc[:errors] = errors
    end
end

class Grader
    attr_accessor :logger
    def initialize(testcases, student_code, library=nil)
        @testcases    = testcases
        @student_code = student_code
        @test_main    = File.basename(student_code)
        @test_dir     = File.dirname(student_code)
        if library && library != '.' && library != ''
            @lib_dir      = File.dirname(library)
            @lib_main     = File.basename(library)
        else 
            @lib_dir = '.'
            @lib_main = ''
        end
    end
    def run()
        checker = Checker.new(
            checker_cmd(@test_dir, @test_main, @lib_dir, @lib_main),
            cmper_cmd(@lib_dir, @lib_main),
            @testcases
        )
        checker.logger = @logger
        return checker.run()
    end
end

Dir.glob(File.dirname(__FILE__) + "/lang/*/init.rb").each{|entry|
    load entry
}
