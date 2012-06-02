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

class Problem < ActiveRecord::Base
	belongs_to :assignment
	belongs_to :comparator
	has_many :testcases

	# Optimized
	def max_score
		Problem.sum(
			'testcases.points',
			:joins => 'INNER JOIN testcases 
                        ON problems.id = testcases.problem_id',
			:conditions => ['problems.id = ?', self.id]
		) || 0
	end
	# Optimized
	def score(submission)
		Submission.sum(
			'testcases.points',
			:joins => 'INNER JOIN testcase_outputs
			             ON testcase_outputs.submission_id = submissions.id
			           INNER JOIN testcases
			             ON testcases.id = testcase_outputs.testcase_id
			           INNER JOIN problems
			             ON problems.id = testcases.problem_id',
			:conditions => ['submissions.id = ? AND
			                 problems.id = ? AND
			                 testcase_outputs.success = true',
			                 submission.id,
			                 self.id]
		) || 0
	end

end
