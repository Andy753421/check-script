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

class TestcaseOutputKeys < ActiveRecord::Migration
	def self.up
		remove_index "testcase_outputs", :name => "testout_fk_testcase"
		remove_index "testcase_outputs", :name => "testout_fk_submission"
		execute("
			ALTER TABLE `testcase_outputs`
			ADD PRIMARY KEY (`testcase_id`, `submission_id`)
		")
	end
	def self.down
		execute("
			ALTER TABLE `testcase_outputs`
			DROP PRIMARY KEY
		")
		add_index "testcase_outputs", ["testcase_id"],   :name => "testout_fk_testcase"
		add_index "testcase_outputs", ["submission_id"], :name => "testout_fk_submission"
	end
end
