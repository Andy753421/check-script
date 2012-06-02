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

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
    require "#{RAILS_ROOT}/app/helpers/application_helper.rb"
	# Pick a unique cookie name to distinguish our session data from others'
	session :session_key => '_plc_web_interface_session_id'
	def login_required
		if session[:user_id]
			return true
		end
		flash[:warning] = 'Please login to continue'
		session[:return_to] = request.request_uri
		redirect_to :controller => "user", :action => "login"
		return false
	end
	def admin_required
		return false unless login_required
		if session[:user].professor? || session[:user].ta?
			return true
		end
		flash[:warning] = 'You do not have access to this page'
		session[:return_to] = request.request_uri
		redirect_to :controller => "user", :action => "login"
		return false
	end
	def redirect_to_stored
		if return_to = session[:return_to]
			session[:return_to] = nil
			redirect_to_url(return_to)
		else
			redirect_to :controller=>'user', :action=>'menu'
		end
	end
end
