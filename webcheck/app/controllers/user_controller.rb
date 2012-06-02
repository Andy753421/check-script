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
#require 'application.rb'

require "application.rb"
class UserController < ApplicationController
	filter_parameter_logging "password"

	def index
		user = User.find(session[:user_id])
		send_off(user)
	end

	# Login View
	def login()
		# Already logged in
		user = session[:user_id] && User.find(session[:user_id])
		if (user)
			send_off(user)
		end
	end
	# Login Callbacks
	def login_submit()
		username = params[:user][:username]
		password = params[:user][:password]
		if session["person"] = User.authenticate(username, password)
			user = User.find(:first, :conditions => "username = '#{username}'")
			if user == nil
				flash[:error] = 'Cannot find user in database...'
				redirect_to :action => 'login'
			elsif !user.active
				flash[:error] = 'User account is no longer active'
				redirect_to :action => 'login'
			else
				session[:user_id] = user.id
				session[:user] = user
				flash[:notice] = 'Logged in as ' + username
				if session["return_to"]
					redirect_to_path(session["return_to"])
				else
					send_off(user)
				end
			end
		else
			flash[:error] = "Authentication failed!"
			redirect_to :action => "login"
		end
	end

	# Logout View
	def logout()
		reset_session
		flash[:notice] = 'Logged off successfully'
		redirect_to :action => 'login'
	end

	# make this 'private' somehow
	def send_off(user)
		if (user.student?)
			redirect_to :controller => 'student',
				    :action     => 'assignment'
		elsif (user.ta?)
			redirect_to :controller => 'submission',
				    :action     => 'assignment'
		elsif (user.professor?)
			redirect_to :controller => 'assignment',
				    :action     => 'edit'
		else
			redirect_to :action     => 'login'
		end
	end
end
