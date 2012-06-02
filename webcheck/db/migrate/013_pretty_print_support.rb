# Copyright (C) 2007, 2008, 2009 Jason Sauppe
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

class PrettyPrintSupport < ActiveRecord::Migration
    def self.up
        add_column :assignments, :output_width, :integer
        add_column :assignments, :error_width, :integer
        add_column :assignments, :testcase_width, :integer
        add_column :assignments, :testcase_height, :integer
        add_column :assignments, :answer_width, :integer
        add_column :assignments, :answer_height, :integer
        add_column :problems, :output_width, :integer
        add_column :problems, :error_width, :integer
        add_column :problems, :testcase_width, :integer
        add_column :problems, :testcase_height, :integer
        add_column :problems, :answer_width, :integer
        add_column :problems, :answer_height, :integer

        create_table "global_vars" do |t|
            t.column "varname", :string, :limit => 25
            t.column "value", :integer
        end
    end

    def self.down
        remove_column :assignments, :output_width
        remove_column :assignments, :error_width
        remove_column :assignments, :testcase_width
        remove_column :assignments, :testcase_height
        remove_column :assignments, :answer_width
        remove_column :assignments, :answer_height
        remove_column :problems, :output_width
        remove_column :problems, :error_width
        remove_column :problems, :testcase_width
        remove_column :problems, :testcase_height
        remove_column :problems, :answer_width
        remove_column :problems, :answer_height
        drop_table "global_vars"
    end
end
