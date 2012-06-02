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
class AdminController < ApplicationController
    before_filter :admin_required
    def index
        redirect_to :action => 'user'
    end

    # User View
    def user()
        # Seems like there should be an easier way to sort this, 
        # but I can't think of it right now (want to sort by role 
        # (Prof > TA > Student) then by username)
        @users = User.find(:all).sort{|x, y| 
            if (x.role == y.role)
                x.username <=> y.username
            elsif x.professor? || y.student?
                (-1)
            elsif y.professor? || x.student?
                (1)
            else
                (0)
            end
        }
        @active_students = User.find(:all, :conditions => 
                    {:role => 'Student', :active => true}).length
        if User.find(:first, :conditions => 
                {:username => 'student'}) != nil
            @active_students = @active_students - 1
        end
        @roles = ['Student', 'TA', 'Professor']
        @tabs = create_tabs(:user)
    end

    # User callbacks
    def user_add()
        @user = User.new(params[:user])
        if @user.save
            flash[:notice] = 'User added.'
        else
            flash[:error] = 'User could not be added.'
        end
        redirect_to :action => 'user'
    end

    def user_mod()
        @user = User.find(params[:user_id])
        if @user.update_attributes(params[:user])
            flash[:notice] = 'User edited.'
        else
            flash[:error] = 'User could not be edited.'
        end
        redirect_to :action => 'user'
    end

    def user_del()
        if  User.find(params[:user_id]).destroy
            flash[:notice] = 'User deleted.'
        else
            flash[:error] = 'Could not delete the user.'
        end
        redirect_to :action => 'user'
    end

    def user_add_list()
        user_list = params[:user_list][:usernames].split(/[^a-zA-Z0-9]/)

        success = 'Successfully added: '
        failure = 'Failed to add: '
        success_count = 0
        failure_count = 0

        user_list.each do |username|
            if username.chomp == ''
                next
            end
            user = User.new(:username => username)#student by default
            if user.save
                success += "#{username}; "
                success_count += 1
            else
                failure += "#{username}; "
                failure_count += 1
            end
        end
        if success_count > 0
            flash[:notice] = success
        end
        if failure_count > 0
            flash[:error] = failure
        end
        redirect_to :action => 'user'
    end

    # Comparator View
    def comparator()
        @comparators = Comparator.find(:all)
        @tabs = create_tabs(:comparator)
    end
    # Comparator Callbacks
    def comparator_add()
        @comparator = Comparator.new(params[:comparator])
        if @comparator.save
            flash[:notice] = 'Comparator added.'
        else
            flash[:error] = 'Comparator could not be added.'
        end
        redirect_to :action => 'comparator'
    end
    def comparator_mod()
        @comparator = Comparator.find(params[:comp_id])
        if @comparator.update_attributes(params[:comparator])
            flash[:notice] = 'Comparator updated.'
        else
            flash[:error] = 'Comparator could not be updated'
        end
        redirect_to :action => 'comparator'
    end
    def comparator_del()
        if Comparator.find(params[:comp_id]).destroy
            flash[:notice] = 'Comparator deleted.'
        else
            flash[:error] = 'Comparator could not be deleted.'
        end
        redirect_to :action => 'comparator'
    end

    # Module View
    def module()
        @tabs = create_tabs(:module)
        @modules = Dir.glob("#{RAILS_ROOT}/modules/*").map{|mod|
            File.basename(mod)
        }
    end
    def module_add()
        file = params['module']['file']
        data = file.read
        name = file.original_filename
        fd = File.new("#{RAILS_ROOT}/modules/#{name}", "w+")
        fd.write(data)
        fd.close
        redirect_to :action => 'module'
    end
    def module_del()
        fd = File.unlink("#{RAILS_ROOT}/modules/#{params['name']}")
        redirect_to :action => 'module'
    end

    # Module show View
    def module_show()
        @name = params['name']
        @data = File.read("#{RAILS_ROOT}/modules/#{@name}")
    end

    # Assignment View
    def assignment()
        @assignments = 
            Assignment.find(:all).sort{|x,y| 
                    if (x.name == nil)
                        (-1)
                    elsif (y.name == nil)
                        (1)
                    else
                        (x.name <=> y.name)
                    end }
        # Need to check for assignments without a name, 
        # this is not guaranteed to be non-null 
        @tabs = create_tabs(:assignment)
    end

    def assignment_import_new()
        as = Assignment.new
        as.save
        result = as.import_from_new_format(params[:assignment][:file])
        if result
            flash[:notice] = 'Import succeeded'
            as.save
        else
            flash[:error] = 'Problem during import process, make sure that ' + 
                            'YAML syntax is valid'
            Assignment.delete(as.id)
        end
        redirect_to :controller => 'admin',
                    :action => 'assignment'
    end 

    def assignment_import_old()
        as = Assignment.new
        as.save
        result = as.import_from_old_format(params[:assignment][:file])
        if result
            flash[:notice] = 'Import succeeded'
            as.save
        else
            flash[:error] = 'Problem during import process, make sure ' + 
                            '.dat file has the correct format'
            Assignment.delete(as.id)
        end
        redirect_to :controller => 'admin', 
                    :action => 'assignment'
    end

    # Assignment Callbacks
    def assignment_mod()
        as = Assignment.find(params[:as_id])
        as.update_attributes(params[:assignment])
        if as.save
            flash[:notice] = 'Assignment successfully edited.'
        else
            flash[:error] = 'Experienced some error while attempting ' + 
                            'to edit the assignment.'
        end
        redirect_to :action => 'assignment'
    end
    def assignment_del()
        # Need to delete everything associated with this assignment
        

        as = Assignment.find(params[:as_id])
        as.problems.each {|prob|
            prob.testcases.each {|tc|
                tc.destroy
            }
            prob.destroy
        }
        
        # Deleteing submissions should clean up submitted files and 
        # testcase outputs as well
        as.submissions.each {|sub|
            sub.delete_files_and_outputs(sub.id)
            sub.destroy
        }
        if as.destroy
            flash[:notice] = 'Assignment successfully deleted.'
        else
            flash[:error] = 'Could not delete the assignment.'
        end
        redirect_to :action => 'assignment' 
    end
    def assignment_cp()
        as = Assignment.find( params[:as_id] ).clone
        as.id = nil
        as.name = "Copy of #{as.name}"
        as.save
        Assignment.find( params[:as_id] ).problems.each do |prob|
            new_prob = prob.clone
            new_prob.id = nil
            prob.testcases.each do |tc|
                new_tc = tc.clone
                new_tc.id = nil
                new_tc.save
                new_prob.testcases << new_tc
            end
            new_prob.save
            as.problems << new_prob
        end
        as.save
        redirect_to :action => 'assignment'
    end
    def assignment_dump()
        @as = Assignment.find(params[:as_id])
    end

    def globalvars()
        vars = ["maxtime", "output_width", "error_width", "testcase_width", 
                "testcase_height", "answer_width", "answer_height"]
        vars.each do |var|
            # Need to make sure that var exists in global vars table
            gv = GlobalVar.find(:first, :conditions => { :varname => var })
            if gv == nil
                gv = GlobalVar.new
                gv.varname = var
                gv.value = 10
                gv.save
            end
        end
        @tabs = create_tabs(:globalvars)
        gvs = GlobalVar.find(:all)
        @globalvars = {}
        gvs.each do |gv| 
            @globalvars[gv.varname] = gv.value
        end 
    end

    def var_mod()
        @globalvar = GlobalVar.find(:first, 
            :conditions => { :varname => params[:var_name] })
#        @globalvar.update_attributes :value => params[:globalvar][:val]
        @globalvar.value = params[:globalvar][:val]
        if @globalvar.save
            flash[:notice] = 'Global variable value updated.'
        else
            flash[:error] = 'Global variable could not be updated'
        end
        redirect_to :action => 'globalvars'
    end

    # Helper functions
    def create_tabs(action)
        return [ 
            {:name => 'Users', 
             :link => url_for(:action => 'user'),
             :active => action == :user},
            {:name => 'Comparators', 
             :link => url_for(:action => 'comparator'), 
             :active => action == :comparator},
            {:name => 'Modules',     
             :link => url_for(:action => 'module'),
             :active => action == :module},
            {:name => 'Assignments', 
             :link => url_for(:action => 'assignment'), 
             :active => action == :assignment},
            {:name => 'Global Variables',
             :link => url_for(:action => 'globalvars'),
             :active => action == :globalvars}
        ]
    end

end
