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

class Testcase < ActiveRecord::Base
	has_many :testcase_outputs
	belongs_to :problem
	belongs_to :comparator

	# Optimized
	def score(submission)
		tco = TestcaseOutput.find(
			:first,
			:conditions =>
				['testcase_outputs.success = true AND
				 submission_id = ? AND
				 testcase_id = ?',
				 submission.id,
				 self.id]
		)
		if tco
			return self.points
		else
			return 0
		end
	end

	def studentOutput(submission)
		tc_outputs = submission.testcase_outputs
		tc_outputs.each {|tco|
			# Added nil check, not sure why some testcases are nil though
			if ((!tco.testcase.nil?) && (tco.testcase.id == self.id))
				return tco.student_output
			end
		}
		return "Not Found"
	end

	def studentErrors(submission)
		tc_outputs = submission.testcase_outputs
		tc_outputs.each {|tco|
			# Added nil check, not sure why some testcases are nil though
			if ((!tco.testcase.nil?) && (tco.testcase.id == self.id))
				return tco.student_errors
			end
		}
		return "Not Found"
	end

	def get_comparator()
		unless @comparator.nil? 
			return @comparator.name
		end
		if @problem.nil? || (@problem.comparator.nil? && @problem.assignment.nil?) || @problem.assignment.comparator.nil?
			return "Default"
		end
		unless @problem.comparator.nil
			return @problem.comparator.name
		end
		unless @problem.assignment.comparator.nil?
			return @problem.assignment.comparator.name
		end
#		@comparator.nil? ? (@problem.comparator.nil? ? (@problem.assignment.comparator.nil? ? "Default" : @problem.assignment.comparator.name) : @problem.comparator.name) : @comparator.name #this code generated a bug and was thus rewritten as it is above
	end
end
