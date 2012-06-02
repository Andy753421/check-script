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
class AssignmentController < ApplicationController
    before_filter :admin_required
    def index
        redirect_to :action => 'edit'
    end

    # Edit View
    def edit()
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
        # sort the assignments lexicographically
        # Need to check for assignments without a name, this is not guaranteed 
        # to be non-null 


        @assignment = Assignment.find(params[:as_id] || :first)
        @comparators= Comparator.find(:all)
        #@problems = @assignment.problems
        # NOTE: commented because of redundancy
        # Is using @assignment.problems in the view preferred? -Andy
        # Either is okay, as long as we only use one in the view
        # @problems wasn't used, so I removed its instantiation. -Corey
        @tabs = @assignments.map { |as| {
            :name   => as.name,
            :link   => {:as_id => as.id},
            :active => as == @assignment
        } }
        @tabs.insert(0, {
            :name => 'New',
            :link => {:action => 'edit_assignment_add'},
            :active => false
        })
    end
    # Edit Callbacks
    def edit_assignment_add()
        as = Assignment.new
        as.save
        redirect_to :action => 'edit', 
                    :as_id => as.id
    end
    # Assignment import
    #def edit_assignment_import()
    #   as = Assignment.new
    #   @import_results = as.create_from_dat_file(params[:file])
    #   if @import_results.nil?
    #       flash[:error] = 'Import unsuccessful'
    #   else
    #       flash[:notice] = 'Import successful'
    #   end
    #   redirect_to :action => 'test_display'
    #end
    
    def edit_assignment_mod()
        as = Assignment.find(params[:as_id])
        as.update_attributes(params[:assignment])
        if as.save
            flash[:notice] = 'Assignment successfully edited.'
        else
            flash[:error] = 'Experienced some error while attempting ' + 
                            'to edit the assignment.'
        end
        redirect_to :action => 'edit',
                    :as_id => params[:as_id]
    end

    def edit_problem_add()
        pr = Problem.new(params[:problem])
        flash[:notice] = 'Problem added' if pr.save
        redirect_to :action => 'edit', 
                    #:view => 'assignment',
                    :as_id => params[:as_id] 
    end

    def edit_problem_del()
        prob = Problem.find(params[:prob_id])
        as_id = prob.assignment.id
        if !prob.testcases.empty?
            prob.testcases.each do |tc|
                TestcaseOutput.delete_all(:testcase_id => tc.id)
                tc.destroy
            end
        end
        if prob.destroy
            flash[:notice] = 'Problem deleted'
        else
            flash[:error] = 'Could not delete the problem'
        end
        redirect_to :action => 'edit', 
                    #:view => 'assignment', 
                    :as_id => as_id
    end

    def edit_problem_cp()
        prob = Problem.find(params[:problem][:id])
        new_as = Assignment.find(params[:assignment][:id])
        new_prob = prob.clone
        new_prob.id = nil
        prob.testcases.each do |tc|
            new_tc = tc.clone
            new_tc.id = nil
            new_tc.save
            new_prob.testcases << new_tc
        end
        new_prob.save
        new_as.problems << new_prob
        new_as.save
        flash[:notice] = 'Problem copied'
        redirect_to :action => 'edit', 
                    :as_id => params[:as_id]
    end

    def edit_testcase_add()
        if Testcase.new(params[:testcase]).save
            flash[:notice] = 'Testcase added'
        else
            flash[:error] = 'Could not add the testcase'
        end
        redirect_to :action => 'edit', 
                    #:view => 'assignment',
                    :as_id => params[:as_id] 
    end

    def edit_testcase_del()
        # Added to delete testcase outputs associated with this testcase
        TestcaseOutput.delete_all(:testcase_id => 
                                params[:testcase][:id])
        
        if Testcase.find(params[:testcase][:id]).destroy
            flash[:notice] = 'Testcase deleted'
        else
            flash[:error] = 'Could not delete the testcase'
        end
        redirect_to :action => 'edit', 
                    #:view => 'assignment', 
                    :as_id => params[:as_id]
    end

    def edit_testcase_cp()
        tc = Testcase.find(params[:testcase][:id])
        prob = Problem.find(params[:problem][:id])
        new_tc = tc.clone
        new_tc.id = nil
        new_tc.save
        prob.testcases << new_tc
        flash[:notice] = 'Testcase copied'
        redirect_to :action => 'edit', 
                    :as_id => params[:as_id]
    end
end
