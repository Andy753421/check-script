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

require "application.rb"
class HelpController < ApplicationController
	before_filter :create_tabs
	def index
		redirect_to :action => 'student'
	end
	
	# idea is to only show About and Student Help tabs to students, but to show all tabs to TAs and Professors
	# However, any user can enter url help/assignment etc. to get to any of the pages
	# Would like to fix this somehow
	def create_tabs()
		tabs_temp = [[:about,       "About"],
		             [:student,     "Student Help"],
		             [:development, "Development"]]
		if session[:user].ta? || session[:user].professor?
			tabs_temp << [:assignment,  "Assignment Help"]
			tabs_temp << [:submission,  "Submission Help"]
			tabs_temp << [:admin,       "Admin Help"]
		end
		@tabs = tabs_temp.map {|id, desc| {
			:name   => desc,
			:link   => url_for(:action => id.to_s),
			:active => params[:action] == id.to_s
		} }
		return true
	end
	def about()
	end
	def student()
	end
	def assignment()
	end
	def submission()
	end
	def admin()
	end
	def development()
	end
end
