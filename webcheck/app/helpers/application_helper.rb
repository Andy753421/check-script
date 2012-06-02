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

#def label_tag(name, text = nil)
#   "<label for=\"#{name}}\">#{text}</label>" 
#end
module ApplicationHelper 
    def label(object, label, text = nil)
        "<label for=\"#{object}_#{label}\">#{text}</label>" 
    end

    def select_field(object, label, options)
        "<select id=\"#{object}_#{label}\" name=\"#{object}[#{label}]\">#{options}</select>"
    end

    def notebook(tabs, &block)
        if (tabs == nil)
            return yield
        end
        bconcat = lambda {|str|
            concat(str, block.binding)
        }
        bconcat['<div class="notebook">']
        bconcat['   <ul class="tabbar">']
        tabs.each do |tab| 
            if tab[:active]
                bconcat['<li class="tab active">']
                bconcat["<a style=\"color:white\" 
                        href=\"#{url_for(tab[:link])}\">
                        #{tab[:name] || "_NEW_"}</a> </li>"]
                #bconcat[(tab[:name] || "_NEW_") + '</li>']
            elsif tab
                bconcat['<li class="tab">']
                bconcat["<a href=\"#{url_for(tab[:link])}\">#{tab[:name]}</a>"]
                bconcat['</li>']
            end
        end
        bconcat['   </ul>']
        bconcat['   <div class="tabbody">']
        yield
        bconcat['   </div>']
        bconcat['</div>']
    end
    
    def try_link_to(name, link)
        in_link = true
        link.each {|key,value|
            next if (value == params[key])
            in_link = false
            break
        }
        if in_link
            "<a class=\"semi\" href=\"#{url_for(link)}\">#{name}</a>"
        else
            "<a href=\"#{url_for(link)}\">#{name}</a>"
        end
    end
    
    def generic_select( ary, name, subname, selected=nil)
        "<select id=\"#{name}_#{subname}\" name=\"#{name}[#{subname}]\">" +
            ary.map { |obj|
                sel = (selected && obj.id == selected.id ? 'selected="selected" ' : '')
                "<option #{sel}value=\"#{obj.id}\">#{obj.name}</option>"
            }.join +
        '</select>'
    end
    def comparator_select(name, subname, selected=nil)
        cmps = Comparator.find(:all)
        "<select id=\"#{name}_#{subname}\" name=\"#{name}[#{subname}]\">" + 
            '<option value="nil">Default</option>' +
        cmps.map {|c|
            sel = (selected && c.id == selected.id ? 'selected="selected" ' : '')
            "<option #{sel}value=\"#{c.id}\">#{c.name}</option>"
        }.join + '</select>'
    end
    def assignment_select(name, subname, selected=nil)
        all_as = Assignment.find(:all)
        generic_select( all_as, name, subname, selected )
    end
    def problem_select( ary, name, subname, selected=nil) 
        #since problems don't have .name
        "<select id=\"#{name}_#{subname}\" name=\"#{name}[#{subname}]\">" +
            ary.map { |obj|
                sel = (selected && obj.id == selected.id ? 'selected="selected" ' : '')
                "<option #{sel}value=\"#{obj.id}\">#{obj.description}</option>"
            }.join +
        '</select>'
    end
    def role_select(name, subname, roles, role=nil)
        select_field(name, subname, roles.map{|r|
            "<option#{' selected="true"' if r==role}>#{r}</option>"
        })
    end
    
    def try_include(file)
        if File.exist?("#{RAILS_ROOT}/app/views/layouts/_#{file}.rhtml")
            return render(:partial => "layouts/#{file}")
        end
    end
    
    # Deprecated (The code for this has been moved into the views that used it
    # and modified to suit their purposes)
    def submission_report_short(subs)
        if subs == nil || subs.empty?
            "No submissions"
        else
            @max_score = subs[0].assignment.max_score;
            "<table>
                <tr>
                    <th>Usernames</th>
                    <th>Score</th>
                    <th>Time submitted</th>
                    <th>Reports</th>
                    <th>Files</th>
                    <th>Grade</th>
                </tr>" + 
                subs.map { |sub|
                    "<tr>
                        <td>#{ sub.users.map{|u| u.username}.join(", ") }</td>
                        <td>#{ sub.score } / #{ @max_score }</td>
                        <td>#{ sub.timestamp.strftime("%c") }</td>
                        <td>#{ link_to "View Report", :controller => 'student',
                                                      :action => 'report',
                                                      :sub_id => sub.id }</td>
                        <td>#{ link_to "View Code", :controller => 'student',
                                                    :action => 'code',
                                                    :sub_id => sub.id }</td>
                        <td>#{ link_to "Regrade", :controller => 'student',
                                                  :action => 'assignment_regrade',
                                                  :sub_id  => sub.id }</td>
                    </tr>"
                }.join("\n") + "
            </table>"
        end
    end
    
    # Deprecated (The code for this has been moved into the appropriate views)
    def assignment_details(as)
        if (as != nil)
            "<table class=\"tuple\">
                <tr>
                    <td>Due:</td>
                    <td>#{ as.due.strftime("%c") unless as.due.nil? }</td>
                </tr>
                <tr>
                    <td>Problems:</td>
                    <td>
                        #{ as.problems.map { |prob|
                            "#{prob.description}<br />"
                        }.join("\n") }
                    </td>
                </tr>
            </table>"
        end
    end
    
    def editor(entity, attribute, options={})
        ops = options.map{|k,v| "#{k}=\"#{v}\""}.join(' ')
        attr_val = entity.send(attribute)
        id = "#{entity.class}_#{entity.id}_#{attribute}"
        "<input type=\"text\" id=\"#{id}\" onblur=\"#{
            remote_function(
                :url => {
                    :controller => 'ajax',
                    :action     => 'set',
                    :class      => entity.class,
                    :id         => entity.id,
                    :attr       => attribute,
                },
                :with     => "{value: this.value}",
                :after    => '
                    this.value=\'Saving..\';
                    this.disabled=true;
                ',
                :complete => "
                    f=document.getElementById(\'#{id}\');
                    f.value=request.responseText;
                    f.disabled=false;
                "
            )
        }\" value=\"#{attr_val}\" #{ops} />"
    end
    
    def block_editor(entity, attribute, options={})
        ops = options.map{|k,v| "#{k}=\"#{v}\""}.join(' ')
        attr_val = entity.send(attribute)
        id = "#{entity.class}_#{entity.id}_#{attribute}"
        "<textarea id=\"#{id}\" onblur=\"#{
            remote_function(
                :url => {
                    :controller => 'ajax',
                    :action     => 'set',
                    :class      => entity.class,
                    :id         => entity.id,
                    :attr       => attribute,
                },
                :with     => "{value: this.value}",
                :after    => '
                    this.value=\'Saving..\';
                    this.disabled=true;
                ',
                :complete => "
                    f=document.getElementById(\'#{id}\');
                    f.value=request.responseText;
                    f.disabled=false;
                "
            )
        }\" #{ops} />#{attr_val}</textarea>"
    end
    
    def cmp_block_editor(entity, attribute, options={})
        ops = options.map{|k,v| "#{k}=\"#{v}\""}.join(' ')
        attr_val = entity.send(attribute)
        id = "#{entity.class}_#{entity.id}_#{attribute}"
        "<textarea id=\"#{id}\" #{ops} />#{attr_val}</textarea>"
    end
    
    def cmpr_editor(entity, attribute, options={})
        ops      = options.map{|k,v| "#{k}=\"#{v}\""}.join(' ')
        attr_val = entity.send(attribute)
        id       = "#{entity.class}_#{entity.id}_#{attribute}"
        cmprs    = Comparator.find(:all)
        "<select type=\"text\" id=\"#{id}\" onblur=\"#{
            remote_function(
                :url => {
                    :controller => 'ajax',
                    :action     => 'set',
                    :class      => entity.class,
                    :id         => entity.id,
                    :attr       => attribute,
                },
                :with     => '\'value=\'+this.value',
                :after    => "
                    this.value='Saving..';
                    this.disabled=true;
                ",
                :complete => "
                    f=document.getElementById(\'#{id}\');
                    f.value=request.responseText;
                    f.disabled=false;
                "
            )
        }\" #{ops}>" +
            '<option value="nil">Default</option>' +
            cmprs.map { |cmpr|
                sel = (entity.comparator && cmpr.id == entity.comparator.id ? 'selected="selected" ' : '')
                "<option #{sel}value=\"#{cmpr.id}\">#{cmpr.name}</option>"
            }.join +
        '</select>'
    end

# These methods were moved into submission.rb since that's where they are used  
#    def outputWidth(prob)
#        if prob.output_width != nil
#            return prob.output_width
#        elsif prob.assignment.output_width != nil
#            return prob.assignment.output_width
#        else
#            return GlobalVar.find(:first, 
#                :conditions => {:varname => "output_width"}).value
#        end
#    end
    
#    def errorWidth(prob)
#        if prob.error_width != nil
#            return prob.error_width
#        elsif prob.assignment.error_width != nil
#            return prob.assignment.error_width
#        else
#            return GlobalVar.find(:first, 
#                :conditions => {:varname => "error_width"}).value
#        end
#    end
    
    def tcWidth(prob)
        if prob.testcase_width != nil
            return prob.testcase_width
        elsif prob.assignment.testcase_width != nil
            return prob.assignment.testcase_width
        else
            return GlobalVar.find(:first, 
                :conditions => {:varname => "testcase_width"}).value
        end
    end
    
    def tcHeight(prob)
        if prob.testcase_height != nil
            return prob.testcase_height
        elsif prob.assignment.testcase_height != nil
            return prob.assignment.testcase_height
        else
            return GlobalVar.find(:first, 
                :conditions => {:varname => "testcase_height"}).value
        end
    end
    
    def ansWidth(prob)
        if prob.answer_width != nil
            return prob.answer_width
        elsif prob.assignment.answer_width != nil
            return prob.assignment.answer_width
        else
            return GlobalVar.find(:first, 
                :conditions => {:varname => "answer_width"}).value
        end
    end
    
    def ansHeight(prob)
        if prob.answer_height != nil
            return prob.answer_height
        elsif prob.assignment.answer_height != nil
            return prob.assignment.answer_height
        else
            return GlobalVar.find(:first, 
                :conditions => {:varname => "answer_height"}).value
        end
    end

    def set_focus(id)
        javascript_tag("$(\"#{id}\").focus()")
    end
end
