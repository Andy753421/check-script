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
class StudentController < ApplicationController
    before_filter :login_required
    before_filter :create_tabs

    def index
        redirect_to :action => 'assignment'
    end

    def create_tabs()
        # First locate all assignments that are marked as visible
        vis_assignments = Assignment.find(:all, 
            :conditions => {:visible => true})
        # Then if the user is a student, filter the assignments such that an 
        # assignment is shown only if it's available
        if session[:user].student?
            vis_assignments = vis_assignments.find_all{|as|
                as.available and (Time.now <=> as.available) >= 0}
        end
        # Finally, sort the shown assignments by name
        @assignments = vis_assignments.sort{|x, y|
            if (x.name == nil)
                (-1)
            elsif (y.name == nil)
                (1)
            else
                (x.name <=> y.name)
            end
        }
        cur = find_assignment
        #return false unless cur # removed this
        @tabs = @assignments.map { |as| {
            :name   => as.name,
            :link   => {:action => 'assignment', :as_id => as.id},
            :active => as == cur
        } }
    end

    def find_assignment
        if (params[:as_id]) 
            as = Assignment.find(params[:as_id])
        else
            as = @assignments[0]
        end
        if (as and as.available and ((Time.now <=> as.available) < 0) and 
            session[:user].student?)
            redirect_to :controller => 'student',
                        :action     => 'assignment',
                        :as_id      => nil
            # return false # removed this as well
        end
        as
    end

    # Assignment View
    def assignment()
        @assignment = find_assignment()
        @user = session[:user]
        @submissions = session[:user].submissions.select {|s|
            s.assignment == @assignment
        }.reverse
    end

    # Assignment Callbacks
    def assignment_submit()
        usernames = params[:submission][:users].split(/[^a-zA-Z0-9]+/).uniq
        users = usernames.map{|username|
            user = User.find_username(username)
            if user == nil
                redirect_to :action => 'assignment',
                            :as_id => params[:submission][:assignment_id]
                flash[:error] = "Unknown teammate '#{username}'"
                return false
            end
            user
        }
        if (params[:submission][:submitted_file] == "")
            redirect_to :action => 'assignment',
                        :as_id => params[:submission][:assignment_id]
            flash[:error] = "Invalid filename"
            return false
        end
        #params[:submission][:users] = users | [session[:user]]
        #params[:submission][:submitted_file] =
        all_users = users | [session[:user]]
        sub_file = SubmittedFile.new(params[:submission][:submitted_file])
        @assignment = Assignment.find(params[:submission][:assignment_id])
        if (Time.now < @assignment.available && session[:user].student?)
            redirect_to :controller => 'student'
        end
        @submission = Submission.new do |sub|
            sub.assignment_id = params[:submission][:assignment_id]
            sub.submitted_file = sub_file
            sub.timestamp = Time.now
            sub.users = all_users
            sub.score = 0
        end
        @submission.save
        
        assignment_grade(@submission)
    end

    def assignment_grade(sub)
        result = sub.update_grade
        if (result != :success)
            case result
            when :load_fail
                flash[:error] = "Unable to load your code - please check for 
                                 syntax errors"
            when :unknown_filetype
                flash[:error] = "Unable to load your code - the filetype is 
                                 unknown (see the Student Help page for 
                                 more information)"
            when :mysql_fail
                flash[:error] = "Connection error; try to regrade your code 
                                 but if the problem persists contact the 
                                 developers"
            else
                flash[:error] = "Problem with grading the submission"
            end
            redirect_to :action => 'assignment',
                        :as_id => sub.assignment_id
        else 
            flash[:notice] = "Submission graded successfully"
            redirect_to :action => 'report',
                        :as_id => sub.assignment_id,
                        :sub_id => sub.id
        end
    end
    
    def assignment_regrade()
        sub = Submission.find(params[:sub_id])
        if sub == nil
            flash[:error] = "Cannot find submission to regrade"
            redirect_to :action => 'assignment'
        end
        unless sub.users.include?(session[:user]) ||
                 session[:user].professor? ||
                 session[:user].ta?
            redirect_to :controller => 'student'
        end

        assignment_grade(sub)
    end
    
    def assignment_regrade_all()
        unless session[:user].professor? || session[:user].ta?
            redirect_to :controller => 'student'
        end
        subs_to_regrade = Submission.find(:all, 
            :conditions => {:assignment_id => params[:as_id]})
        if subs_to_regrade == nil || subs_to_regrade.empty?
            flash[:error] = "No submissions exist for this assignment"
        else
            error_count = 0
            subs_to_regrade.each do |sub|
                logger.debug "Regrading submission #{sub.id} #{sub}"
                begin
                    sub.update_grade
                rescue Exception
                    error_count += 1
                    next
                end
            end
            if error_count > 0
                flash[:error] = "Error when re-grading " + 
                                error_count.to_s + " submissions"
            else
                flash[:notice] = "All submissions successfully re-graded"
            end
        end
        redirect_to :controller => 'submission', 
                    :action => 'assignment', 
                    :as_id => params[:as_id]
    end

    # Report View
    def report()
        @submission = Submission.find(params[:sub_id] || :first)
        unless @submission.users.include?(session[:user]) ||
                 session[:user].professor? ||
                 session[:user].ta?
            redirect_to :controller => 'student'
        end
        @assignment  = @submission.assignment
    end
    
    # Code View
    def code()
        @submission = Submission.find(params[:sub_id] || :first)
        unless @submission.users.include?(session[:user]) ||
                 session[:user].professor? ||
                 session[:user].ta?
            redirect_to :controller => 'student'
        end
        @assignment = @submission.assignment
        file = @submission.submitted_file
        if file.filetype != "text/scheme"
            send_data file.data, :filename => file.name, 
                                 :type => file.filetype
        end
    end

end
