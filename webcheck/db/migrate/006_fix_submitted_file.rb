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

class FixSubmittedFile < ActiveRecord::Migration
	def self.up
		add_column :submitted_files, :submission_id, :integer,  :null => false
		subs = Submission.find(:all)
		subs.each {|sub|
			file = SubmittedFile.find(sub.submitted_file_id)
			file.submission_id = sub.id
			file.save
		}
		add_index "submitted_files", ["submission_id"], :name => "submitted_file_fk_submission"
		remove_column :submissions, :submitted_file_id
	end

	def self.down
		add_column :submissions, :submitted_file_id, :integer,  :null => false
		subs = Submission.find(:all)
		subs.each {|sub|
			file = sub.submitted_file
			sub.submitted_file_id = file.id
			sub.save
		}
		add_index "submissions", ["submitted_file_id"], :name => "submission_fk_file"
		remove_column :submitted_files, :submission_id
	end
end
