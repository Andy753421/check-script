# Copyright (C) 2007, 2008 Corey Kump
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

class CreateDb < ActiveRecord::Migration
	def self.up

		create_table "assignments" do |t|
			t.column "name",  :string
			t.column "maxtime",          :integer
			t.column "available",        :datetime
			t.column "due",              :datetime
			t.column "comparator_id",    :integer
		end

		add_index "assignments", ["comparator_id"], :name => "assignment_fk_comparator"

		create_table "comparators" do |t|
			t.column "name", :string, :null => false
			t.column "code", :text, :null => false
		end

		create_table "problems" do |t|
			t.column "assignment_id",  :integer, :null => false
			t.column "number", :integer, :null => false
			t.column "maxtime",        :integer
			t.column "description",    :text
			t.column "comparator_id",  :integer
		end

		add_index "problems", ["assignment_id"], :name => "problem_fk_assignment"
		add_index "problems", ["comparator_id"], :name => "problem_fk_comparator"

		create_table "submissions" do |t|
			t.column "user_id",            :integer,  :null => false
			t.column "submitted_file_id",  :integer,  :null => false
			t.column "timestamp",          :datetime, :null => false
			t.column "assignment_id",      :integer,  :null => false
			t.column "score",              :integer
		end

		add_index "submissions", ["submitted_file_id"], :name => "submission_fk_file"
		add_index "submissions", ["user_id"], :name => "submission_fk_user"

		create_table "submitted_files" do |t|
			t.column "name", :string, :limit => 64
			t.column "data", :binary
			t.column "filetype", :string, :limit => 50
		end

		create_table "testcase_outputs", :id => false do |t|
			t.column "testcase_id",    :integer,                              :null => false
			t.column "submission_id",  :integer,                              :null => false
			t.column "success",         :boolean, :default => true, :null => false
			t.column "student_output", :text,                 :null => false
		end

		add_index "testcase_outputs", ["testcase_id"], :name => "testout_fk_testcase"
		add_index "testcase_outputs", ["submission_id"], :name => "testout_fk_submission"

		create_table "testcases" do |t|
			t.column "problem_id",     :integer,    :null => false
			t.column "test_code",      :text,   	:null => false
			t.column "maxtime",        :integer
			t.column "points",         :integer,    :null => false
			t.column "correct_answer", :text,   	:null => false
			t.column "comparator_id",  :integer
		end

		add_index "testcases", ["problem_id"], :name => "testcase_fk_problem"
		add_index "testcases", ["comparator_id"], :name => "testcase_fk_comparator"

		create_table "users" do |t|
			t.column "username", :string, :limit => 20, :null => false, :unique => true
			t.column "role",     :string, :limit => 20,  :default => "Student", :null => false
		end
	end
	def self.down
		drop_table "assignments"
#		drop_index "assignment_fk_comparator"
		drop_table "comparators"
		drop_table "problems"
#		drop_index "problem_fk_assignment"
#		drop_index "problem_fk_comparator"
		drop_table "submissions"
#		drop_index "submission_fk_file"
		drop_table "submitted_files"
		drop_table "testcase_outputs"
#		drop_index "testout_fk_testcase"
#		drop_index "testout_fk_submission"
		drop_table "testcases"
#		drop_index "testcase_fk_comparator"
#		drop_index "testcase_fk_problem"
		drop_table "users"
	end
end
