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
require "#{RAILS_ROOT}/config/webcheck.conf"
class Assignment < ActiveRecord::Base
    has_many :submissions
    has_many :problems
    belongs_to :comparator
    
    def initialize
        super
        equals = Comparator.find(:all, :conditions => "name = 'equal?'")
        unless equals.empty?
            self.comparator = equals[0]
        end
    end

    def self.find_all(*args)
        unless args[1]
            args[1] = 'due DESC'
        end
        super(*args)
    end

    def self.find(*args)
        if args[1] == nil
            args[1] = {:order => 'due DESC'}
        elsif args[1][:order] == nil
            args[1][:order] = 'due DESC'
        end
        super(*args)
    end

    # Optimized
    def max_score
        Assignment.sum(
            'testcases.points',
            :joins => 'INNER JOIN problems 
                       ON assignments.id = problems.assignment_id
                       INNER JOIN testcases 
                       ON problems.id = testcases.problem_id',
            :conditions => ['assignments.id = ?', self.id]
        ) || 0
    end

    # Optimized
    def self.score(submission)
        Submission.sum(
            'testcases.points',
            :joins => 'INNER JOIN testcase_outputs
                       ON testcase_outputs.submission_id = submissions.id
                       INNER JOIN testcases
                       ON testcases.id = testcase_outputs.testcase_id',
            :conditions => ['submissions.id = ? AND 
                            testcase_outputs.success = true',
                            submission.id]
        ) || 0
    end

    def score(sub)
        Assignment.score(sub)
    end
  
    def export()
        # This is going to be very similar to to_array(), but is written 
        # separately so that we don't break functionality (so there will be 
        # some redundant code, but it will be easier to make modifications 
        # to just this portion of the code
        a_as = {}
        a_as['name']                = self.name
        a_as['maxtime']             = self.maxtime
        a_as['available']           = self.available
        a_as['due']                 = self.due
        a_as['late_day_end']        = self.late_day_end
        if self.comparator
            a_as['comparator']      = self.comparator.code
        else
            a_as['comparator']      = nil
        end
        a_as['module']              = self.module
        a_as['visible']             = self.visible
        a_as['full_report_avail']   = self.full_report_available
        a_as['output_width']        = self.output_width
        a_as['error_width']         = self.error_width
        a_as['testcase_width']      = self.testcase_width
        a_as['testcase_height']     = self.testcase_height
        a_as['answer_width']        = self.answer_width
        a_as['answer_height']       = self.answer_height
        a_as['problems']            = []

        # Problem Details
        self.problems.each{ |prob|
            a_prob = {}
            a_prob['number']            = prob.number
            a_prob['maxtime']           = prob.maxtime
            a_prob['description']       = prob.description
            if prob.comparator
                a_prob['comparator']    = prob.comparator.code
            else
                a_prob['comparator']    = nil
            end
            a_prob['output_width']      = prob.output_width
            a_prob['error_width']       = prob.error_width
            a_prob['testcase_width']    = prob.testcase_width
            a_prob['testcase_height']   = prob.testcase_height
            a_prob['answer_width']      = prob.answer_width
            a_prob['answer_height']     = prob.answer_height
            a_prob['testcases'] = []
            
            # Testcase details
            prob.testcases.each{ |tc|
                a_tc = {}
                a_tc['test_code']       = tc.test_code
                a_tc['maxtime']         = tc.maxtime
                a_tc['points']          = tc.points
                if tc.comparator
                    a_tc['comparator']  = tc.comparator.code
                else
                    a_tc['comparator']  = nil
                end
                a_tc['correct_answer']  = tc.correct_answer
                a_prob['testcases'] << a_tc
            }
            a_as['problems'] << a_prob
        }
        a_as
    end
 
    def import_from_new_format(file)
        require 'yaml'
        begin
            data = YAML.load(file.read)
        rescue Exception => e
            return false
        end
        self.name = data['name']
        self.maxtime = data['maxtime']
        self.available = data['available']
        self.due = data['due']
        self.late_day_end = data['late_day_end']
        # For some unknown reason the comparator_id for an assignment always 
        # gets reset to 1 despite the fact that we are setting it correctly
        # Everything else seems to work, though, so this will be looked at 
        # later...
        comp_id = generate_comparator_id_from_code(data['comparator'])
        self.comparator_id = comp_id
        #puts 'Assigned id is ' + self.comparator_id.to_s
        #self.save!
        #self.comparator_id = comp_id
        #self.save
        #puts 'Testing, assigned id is ' + self.comparator_id.to_s
        self.module = data['module']
        self.visible = data['visible']
        self.full_report_available = data['full_report_avail']
        self.output_width = data['output_width']
        self.error_width = data['error_width']
        self.testcase_width = data['testcase_width']
        self.testcase_height = data['testcase_height']
        self.answer_width = data['answer_width']
        self.answer_height = data['answer_height']
        self.save

        probHashes = data['problems']
        probHashes.each {|probHash|
            prob = Problem.new
            prob.assignment_id = self.id
            if probHash['number']
                prob.number = probHash['number']
            else
                prob.number = 1
            end
            prob.maxtime = probHash['maxtime']
            prob.description = probHash['description']
            prob.comparator_id = 
                generate_comparator_id_from_code(probHash['comparator'])
            prob.output_width = probHash['output_width'] 
            prob.error_width = probHash['error_width']
            prob.testcase_width = probHash['testcase_width']
            prob.testcase_height = probHash['testcase_height']
            prob.answer_width = probHash['answer_width']
            prob.answer_height = probHash['answer_height']
            prob.save

            tcHashes = probHash['testcases']
            tcHashes.each {|tcHash|
                tc = Testcase.new
                tc.test_code = tcHash['test_code']
                tc.maxtime = tcHash['maxtime']
                tc.points = tcHash['points']
                tc.correct_answer = tcHash['correct_answer']
                tc.comparator_id = 
                    generate_comparator_id_from_code(tcHash['comparator'])
                tc.problem_id = prob.id
                tc.save
                prob.testcases << tc
            }
            prob.save
            self.problems << prob
            self.save
        }
        return true
    end
 
    def import_from_old_format(datFile)
        # Write the contents of the datFile to a temporary file
        temp_file = File.new("#{RAILS_ROOT}/tmp/temp_dat_import", "w+")
        temp_file.sync = true
        temp_file.write(datFile.read)
        temp_file.close
                
        # Create the parser IO object to interact with the 
        # scheme_parse.ss program   
        @parser.close if @parser != nil && !@parser.closed?
        @parser = IO.popen($parse_cmd % [File.dirname("#{temp_file.path}")], 
                           "w+")
        @parser.sync = true

        # Write the contents of the dat file (now in the temporary file) 
        # to the scheme_parse program (should be in the right directory)
        @parser.puts("temp_dat_import")

        # Obtain the results of the scheme_parse program using gets
        if (line = @parser.gets) != nil
            self.name = line.strip
        end
        
        # Begin reading from the file
        line = @parser.gets
        while line != nil do
            line = line.strip
            prob_number = 0
            if line.eql?("*new_problem*")
                prob_number += 1
                problem = Problem.new
                problem.description = @parser.gets.strip
                problem.assignment_id = self.id
                problem.number = prob_number
                problem.comparator_id = 
                    generate_comparator_id_from_name(@parser.gets.strip)
                problem.save
                
                # Iterate through all of the test case information 
                # for this problem
                while ((line = @parser.gets) != nil) && 
                       ((line = line.strip) != "*new_problem*") do
                    tc = Testcase.new
                    tc.points = line.to_i
                    tc.correct_answer = @parser.gets.strip
                    tc.test_code = @parser.gets.strip
                    tc.problem_id = problem.id
                    tc.save
                    problem.testcases << tc
                end
                
                # Save the problem and move on
                problem.save
                self.problems << problem
            else
                # If this happens, the .dat file is not in the correct format
                return false
            end
        end     

        # Close the IO object and return the array of results
        @parser.close
        File.delete("#{temp_file.path}")
        return true
    end
    
    # Takes the name of the comparator, creates it if it doesn't exist, 
    # and returns the id for it
    def generate_comparator_id_from_name(comparator_name)
        comparators = Comparator.find(:all, :conditions => 
                                      {:name => comparator_name})
        if comparators.nil? || comparators.empty? 
            # need to create a new comparator
            new_comp = Comparator.new
            new_comp.name = comparator_name
            new_comp.code = "(lambda (x y) (" + comparator_name + " x y))"
            new_comp.save
            return new_comp.id
        else
            return comparators[0].id
        end
    end

    def generate_comparator_id_from_code(comparator_code)
        if comparator_code == nil
            return nil
        end
        comps = Comparator.find(:all, :conditions => 
                                        {:code => comparator_code})
        if comps.nil? || comps.empty?
            new_comp = Comparator.new
            new_comp.name = 'TEMP'
            new_comp.code = comparator_code
            new_comp.save
            # Not sure if ID is assigned after we create new or after 
            # first save, but this ensures that it's valid
            new_comp.name = 'NewComp-' + new_comp.id.to_s
            new_comp.save
            return new_comp.id
        else
            return comps[0].id
        end
    end

    def to_array(include_tc=false)
        # Should retrieve the global max time if no maxtime is defined 
        # for the assignment
        if self.maxtime == nil
            maxTime = GlobalVar.find(:first, 
                         :conditions => {:varname => "maxtime" }).value
        else
            maxTime = self.maxtime
        end
        a_as = {}
        a_as[:defaults] = {}
        a_as[:defaults][:maxtime   ] = maxTime
        if (self.comparator)
            a_as[:defaults][:comparator] = self.comparator.code
        else
            a_as[:defaults][:comparator] = "(lambda (x y) (equal? x y))"
        end
        a_as[:testcases] = []
        self.problems.each{ |prob|
            a_prob = {}
            a_prob[:defaults] = {}
            a_prob[:defaults][:maxtime   ] = prob.maxtime if prob.maxtime    
            a_prob[:defaults][:comparator] = 
                prob.comparator.code if prob.comparator 
            a_prob[:testcases] = []
            prob.testcases.each{ |tc|
                a_tc = {}
                a_tc[:_testcase ] = tc if include_tc
                a_tc[:maxtime   ] = tc.maxtime if tc.maxtime
                a_tc[:comparator] = tc.comparator.code if tc.comparator
                a_tc[:test_code ] = formatText(tc.test_code)
                a_tc[:expected  ] = formatText(tc.correct_answer)
                a_prob[:testcases] << a_tc
            }
            a_as[:testcases] << a_prob
        }
        a_as
    end

    def formatText(text)
        # This will remove newlines from the testcode (spaces shouldn't matter)
        # comment lines will also be ignored (comments must start lines)
        if text == nil || text == ""
            return ""
        end
        a = text.split("\n")
        # there should be a better way to map an accumulator function to 
        # this array of text, but this works fine for now
        # NOTE: We should possibly trim out extra whitespace, though this 
        # is not necessary
        buffer = ""
        a.each { |line| 
            if line[0..0] != ';'
                buffer += line + "\n"
            end
        }
        return buffer.gsub("\n", " ")
    end

end
