require File.dirname(__FILE__) + '/../test_helper'
require 'assignments_controller'

# Re-raise errors caught by the controller.
class AssignmentsController; def rescue_action(e) raise e end; end

class AssignmentsControllerTest < Test::Unit::TestCase
  fixtures :assignments

  def setup
    @controller = AssignmentsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @first_id = assignments(:first).id
  end

  def test_index
    get :index
    assert_response :success
    assert_template 'list'
  end

  def test_list
    get :list

    assert_response :success
    assert_template 'list'

    assert_not_nil assigns(:assignments)
  end

  def test_show
    get :show, :id => @first_id

    assert_response :success
    assert_template 'show'

    assert_not_nil assigns(:assignment)
    assert assigns(:assignment).valid?
  end

  def test_new
    get :new

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:assignment)
  end

  def test_create
    num_assignments = Assignment.count

    post :create, :assignment => {}

    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_equal num_assignments + 1, Assignment.count
  end

  def test_edit
    get :edit, :id => @first_id

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:assignment)
    assert assigns(:assignment).valid?
  end

  def test_update
    post :update, :id => @first_id
    assert_response :redirect
    assert_redirected_to :action => 'show', :id => @first_id
  end

  def test_destroy
    assert_nothing_raised {
      Assignment.find(@first_id)
    }

    post :destroy, :id => @first_id
    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      Assignment.find(@first_id)
    }
  end
end
