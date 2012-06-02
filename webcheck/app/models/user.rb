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

require 'ldap'
class User < ActiveRecord::Base
	has_and_belongs_to_many :submissions
	def self.authenticate(username, password)
		return false if password == ''
        if (username == 'student') and (password == 'studentpass')
            return true
        elsif (username == 'admin') and (password == 'adminpass')
            return true
        else
		    begin
                # Commented the following lines out to ignore LDAP 
                # authentication (will need to add these back in after 
                # development)
                conn = LDAP::SSLConn.new("dc-1.rose-hulman.edu", 3269)
    			conn.bind("#{username}@rose-hulman.edu", password)
	    		logger.debug "succeed"
		    	conn.unbind
			    return true
    		rescue LDAP::ResultError => error
	    		logger.debug "fail #{username}:<password>"
		    	logger.debug error # was pretty_inspect 
			    return false
    		end
        end
	end
	def self.find_username(username)
		User.find(:first, :conditions => ["username = ?", username])
	end

	def student?;    self.role == "Student";   end
	def ta?;         self.role == "TA";        end
	def professor?;  self.role == "Professor"; end
end
