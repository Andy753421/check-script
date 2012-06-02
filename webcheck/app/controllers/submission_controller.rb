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
class SubmissionController < ApplicationController
    before_filter :admin_required

    def index
        redirect_to :action => 'assignment'
    end

    # Assignment View
    def assignment()
        # added to make display more readable
        @users = User.find(:all).sort{|x, y| x.username <=> y.username} 

        @assignments = 
            (Assignment.find(:all, 
                             :conditions => {:visible => true})).sort{|x,y| 
                    if (x.name == nil)
                        (-1)
                    elsif (y.name == nil)
                        (1)
                    else
                        (x.name <=> y.name)
                    end }
            # Need to check for assignments without a name, 
            # this is not guaranteed to be non-null

        @assignment = Assignment.find(params[:as_id] || :first)
        if @assignment != nil
#            @submissions = @assignment.submissions.reverse
            @filtered_submissions = filter_submissions(@assignment)
        end
        @_tabs = @assignments.map { |as| {
            :name   => as.name,
            :link   => {:as_id => as.id, 
                        :user_id => params[:user_id]},
            :active => as == @assignment
        } }
#        if params[:user_id]
#            @user = User.find(params[:user_id])
#            @submissions = @submissions.select{|s|
#                s.users.include?(@user)
#            }
#        end
    end

    def all()
        # added to make display more readable
        @users = User.find(:all).sort{|x, y| x.username <=> y.username} 

        @assignments = 
            (Assignment.find(:all, 
                             :conditions => {:visible => true})).sort{|x,y| 
                    if (x.name == nil)
                        (-1)
                    elsif (y.name == nil)
                        (1)
                    else
                        (x.name <=> y.name)
                    end }
            # Need to check for assignments without a name, 
            # this is not guaranteed to be non-null

        @assignment = Assignment.find(params[:as_id] || :first)
        if @assignment != nil
            if (params[:sort_id] == nil)
                @submissions = @assignment.submissions.reverse
            else
                @submissions = @assignment.submissions.sort{|x,y|
                    if ((params[:sort_id] == 'user_asc' ||
                        params[:sort_id] == 'user_desc'))     
                        if (x.users == nil)
                            (-1)
                        elsif (y.users == nil)
                            (1)
                        elsif (x.users[0].username == y.users[0].username)
                            if (params[:sort_id] == 'user_asc')
                                (x.timestamp <=> y.timestamp)
                            else
                                (y.timestamp <=> x.timestamp)
                            end
                        else
                            (x.users[0].username <=> y.users[0].username)
                        end 
                    else
                        if (params[:sort_id] == 'asc')
                            (x.timestamp <=> y.timestamp)
                        else
                            (y.timestamp <=> x.timestamp)
                        end
                    end }
            end
        end
        @_tabs = @assignments.map { |as| {
            :name   => as.name,
            :link   => {:as_id => as.id, 
                        :user_id => params[:user_id]},
            :active => as == @assignment
        } }
        if params[:user_id]
            @user = User.find(params[:user_id])
            @submissions = @submissions.select{|s|
                s.users.include?(@user)
            }
        end
	@submissions ||= []
        @subcount = @submissions.length
    end

    # ActiveStudents are users who are:
    #   Active
    #   Students
    # For all active students find the submission where
    #   submission.assignment_id = current_assignment
    #   the submission is the most recent
    # Retun a list of the submissions as:
    #   [student, submission] (or [st, nil])
    #   (sorted by username)
    def filter_submissions(assignment)
        Submission.find(
            :all,
            :select => 'submissions.*, users.username, submissions.submission_id',
            :from => "( SELECT submissions.*,
                               submissions_users.user_id,
                                   submissions_users.submission_id
                        FROM submissions
                        INNER JOIN submissions_users
                          ON submissions_users.submission_id = submissions.id
                        WHERE submissions.assignment_id = #{assignment.id.to_i}
                        ORDER BY submissions.timestamp DESC ) as submissions
                      RIGHT OUTER JOIN users
                        ON users.id = submissions.user_id",
            :conditions => ['users.active = TRUE AND
                             users.role = "Student"'],
            :group => 'users.id',
            :order => 'users.username'
        )
    end

    def sub_del()
        sub = Submission.find(params[:sub_id])
        as_id = sub.assignment_id
        if !sub.delete_files_and_outputs(params[:sub_id])
            flash[:error] = 'Problem deleting files and/or testcase outputs'
            redirect_to :controller => 'submission',
                        :action => 'assignment',
                        :as_id => as_id
            return
        end

        if sub.destroy
            flash[:notice] = 'Submission deleted'
        else
            flash[:error] = 'Could not delete the submission'
        end
        redirect_to :controller => 'submission',
                    :action => 'assignment',
                    :as_id => as_id
    end

    def submission_remove_all()
        user_list = User.find(:all)
        asn = Assignment.find(params[:as_id])
        if asn == nil
            flash[:error] = "Assignment not found"
            redirect_to :controller => 'submission',
                        :action => 'all'
            return
        end
        time_due = asn.due
        num_error = 0
        user_list.each{|usr|
            usr_subs = asn.submissions.find(:all) do |sub|
                sub.users.include?(usr)
            end
            if usr_subs == nil or usr_subs.empty?
                num_error += 1
                next
            end
               
            subID1 = subID2 = subID3 = usr_subs.first
            usr_subs.each{|sub|
                if sub.timestamp > subID1.timestamp
                    subID1 = sub
                end
                if sub.timestamp <= time_due && 
                   sub.timestamp > subID2.timestamp
                    subID2 = sub
                end
                if sub.score > subID3.score
                    subID3 = sub
                elsif sub.score == subID3.score
                    if sub.timestamp <= subID3.timestamp
                        subID3 = sub
                    end
                end
            }
            subsToPreserve = [ subID1, subID2, subID3 ]
            usr_subs.each{|sub|
                if !subsToPreserve.include?(sub)
                    if !sub.delete_files_and_outputs(sub.id)
                        num_error += 1
                    elsif !sub.destroy
                        num_error += 1
                    end
                end
            }
        }
        if num_error > 0
            flash[:error] = "Error deleting " + num_error.to_s + " submissions"
        else
            flash[:notice] = "All submissions deleted"
        end
        redirect_to :controller => 'submission',
                    :action => 'all',
                    :as_id => params[:as_id]
    end

    def export()
        @users = User.find(:all).sort{|x, y| x.username <=> y.username} 
        @assignments = (Assignment.find(:all, 
            :conditions => {:visible => true})).sort{|x,y| 
            if (x.name == nil)
                (-1)
            elsif (y.name == nil)
                (1)
            else
                (x.name <=> y.name)
            end }
        @assignment = Assignment.find(params[:as_id] || :first)
        if @assignment != nil
            subs = filter_submissions(@assignment)
        else
            subs = []
        end
        @_tabs = @assignments.map {|as| {
            :name   => as.name,
            :link   => {:as_id => as.id, 
                        :user_id => params[:user_id]},
            :active => as == @assignment
        } }
        if params[:user_id]
            @user = User.find(params[:user_id])
            #subs = subs.select{|s| s.users.include?(@user) }
        end

        @scores = ""
        @num_scores = 0
        maxScore = @assignment.max_score 
        subs.each {|sub|
            @scores = @scores + sub.username + ","
            if sub.score
                @scores = @scores + sub.score.to_s + "\n"
            else
                @scores = @scores + 0.to_s + "\n"
            end
            @num_scores = @num_scores + 1
        }
    end

end
