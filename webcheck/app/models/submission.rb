# Copyright (C) 2007, 2008 Corey Kump
# Copyright (C) 2007, 2008 Jason Sauppe
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
class Submission < ActiveRecord::Base
	has_and_belongs_to_many :users
	belongs_to :assignment
	has_many :testcase_outputs
	has_one :submitted_file

    def gen_score
        if self.score == nil
            self.score = calc_score
            self.save
        end
        return self.score
    end

	def calc_score
		# Optimized
		return Assignment.score(self)
	end

	def usernames
		# Optimized
		User.find(
			:first,
			:select =>
			  "GROUP_CONCAT(users.username SEPARATOR ', ') as usernames",
			:joins =>
			  "INNER JOIN submissions_users as su
			     ON su.user_id = users.id",
			:group => 'su.submission_id',
			:conditions => ['submission_id = ?', self.id]
		).usernames
	end

	# Check all the problems and test cases in an assignment
	# \return a nested array with a [correct?, response/error] for test cases
	def update_grade
		require "#{RAILS_ROOT}/vendor/libcheck/libcheck.rb"
        require "#{RAILS_ROOT}/config/webcheck.conf.rb"

		as = self.assignment
		file = self.submitted_file
		prevdir = Dir.pwd
		tmp_dir = `mktemp -d`.strip
		Dir.chdir(tmp_dir)
		sub_file = File.new(self.submitted_file.name, "w")
		sub_file.write(self.submitted_file.data)
		sub_file.close
		case file.filetype
		when "text/scheme"
			student_code = "#{tmp_dir}/#{sub_file.path}"
		when "application/zip"
			st = system("unzip", sub_file.path)
			student_code = "#{tmp_dir}/main.ss"
		when "application/x-tar"
			st = system("tar", "-xf", sub_file.path)
			student_code = "#{tmp_dir}/main.ss"
		when "application/x-rar-compressed"
			st = system("rar", "x", sub_file.path)
			student_code = "#{tmp_dir}/main.ss"
		when "application/x-gzip"
			st = system("gunzip", sub_file.path)
			student_code = "#{tmp_dir}/main.ss"
		when "application/x-bzip2"
			st = system("bunzip2", sub_file.path)
			student_code = "#{tmp_dir}/main.ss"
		else
			logger.debug "Unknown filetype"
			return :unknown_filetype
		end
		Dir.chdir(prevdir)
		logger.info "tmp_dir = #{tmp_dir}"
		if (!File.exists?(student_code))
			logger.debug "Unable to find main scheme file"
			logger.debug "removing #{tmp_dir}"
			`rm -rf #{tmp_dir}`
			return false
		end

		library = (as.module == '' ? nil : "#{RAILS_ROOT}/modules/#{as.module}")

		testcases = as.to_array(true)
		#grader = MzSchemeGrader.new(testcases, student_code, library)
		grader = ChezSchemeGrader.new(testcases, student_code, library)
		grader.logger = logger

        logger.debug "Starting tests..."
        puts "Starting tests..."
        results = grader.run()
        puts "Finished tests..."
        logger.debug "Finished tests..."

        # This seems to be the breaking point - everything works up till here, 
        # then occasionally one of the subsequent MySQL statement breaks
        if results == nil
            logger.debug "Code failed to load..."
            return :load_fail
        end

        # First we can delete any testcase outputs associated with this 
        # submission since we've generated new ones to put into the 
        # database (this is done any time the regrade button is used, since 
        # this will ensure that old testcases get deleted regardless of 
        # any errors when running the program)
        is_successful = false
        num_retries = 3
        while (not is_successful and num_retries > 0)
            begin
                ActiveRecord::Base.verify_active_connections!
                TestcaseOutput.delete_all(["submission_id = ?", self.id])
                is_successful = true
            rescue ActiveRecord::StatementInvalid => e
                is_successful = false
                num_retries = num_retries - 1
            end
        end	

        if num_retries == 0
            logger.debug "Failed to re-establish MySQL connection - aborting"
            return :mysql_fail
        end

        puts "Storing results in database..."

        results[:testcases].each{|prob|
			prob[:testcases].each{|tco|
                is_successful = false
                num_retries = 5
                while (not is_successful and num_retries > 0)
                    begin
                        puts "Storing result..."
                        ActiveRecord::Base.verify_active_connections!
        				tc = tco[:_testcase]
                        results = TestcaseOutput.new
                        results.testcase_id = tc.attributes['id']
                        results.submission_id = @attributes['id']
                        results.success = tco[:status] == :success
                        temp = tc.problem
                        puts "Actual: " + tco[:actual]
                        results.student_output = formatCode(tco[:actual], 
                                outputWidth(temp))
                        puts "Errors: " + tco[:errors]
                        results.student_errors = formatCode(tco[:errors], 
                                errorWidth(temp))
				        results.save
                        is_successful = true
                        puts "Result stored successfully"
                    rescue ActiveRecord::StatementInvalid => e
                        logger.debug 'DB connection lost - retrying...'
                        puts "Lost connection, retrying"
                        is_successful = false
                        num_retries = num_retries - 1
                    end
                end
                if num_retries == 0
                    logger.debug "Failed to re-establish MySQL connection - 
                                  aborting"
                    return :mysql_fail
                end
			}
		}
        puts "Done storing results in DB"
		logger.debug "removing #{tmp_dir}"
		`rm -rf #{tmp_dir}`

        logger.debug "calculating score..."
        self.score = calc_score
        self.save

        return :success
	end

    def formatCode(code, width)
        puts "Pretty-printing: " + code
        if code == nil || code == ""
            return ""
#        elsif code['*error*']
#            # Don't pretty-print if the code is an error message, since 
#            # this seems to be causing a lot of problems
#            return code
        elsif code.length < width
            return code
        elsif invalidScheme(code)
            return code
        else
            @printer.close if @printer != nil && !@printer.closed?
            @printer = IO.popen($print_cmd, "w+")
            @printer.sync = true
            @printer.puts(width) 
            @printer.puts(code)
            buffer = ""
            while (line = @printer.gets) != nil do
                buffer += line
                puts "Buffer: " + buffer
            end
            @printer.close
            return buffer
        end
    end

    def invalidScheme(code)
        parenCount = 0
        for i in (0..code.length - 1)
            if (code[i].chr == '(')
                parenCount += 1
            elsif (code[i].chr == ')')
                parenCount -= 1
            else
                next
            end
        end
        return parenCount != 0
    end

    def delete_files_and_outputs(sub_id)
        sub = Submission.find(sub_id)
        
        # Want to delete all associated submitted files and testcase outputs
        subFile = sub.submitted_file
        if subFile != nil
            if !subFile.destroy
                return false
            end
        end

        TestcaseOutput.delete_all(:submission_id => sub_id)

        return true
    end

    
    # These were included in ApplicationHelper, but for some reason they 
    # weren't being found correctly
    def outputWidth(prob)
        if prob.output_width != nil
            return prob.output_width
        elsif prob.assignment.output_width != nil
            return prob.assignment.output_width
        else
            return GlobalVar.find(:first,
                :conditions => {:varname => "output_width"}).value
        end
    end

    def errorWidth(prob)
        if prob.error_width != nil
            return prob.error_width
        elsif prob.assignment.error_width != nil
            return prob.assignment.error_width
        else
            return GlobalVar.find(:first,
                :conditions => {:varname => "error_width"}).value
        end
    end

end
