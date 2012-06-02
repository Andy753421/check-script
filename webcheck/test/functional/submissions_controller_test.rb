require File.dirname(__FILE__) + '/../test_helper'
require 'submissions_controller'

# Re-raise errors caught by the controller.
class SubmissionsController; def rescue_action(e) raise e end; end

class SubmissionsControllerTest < Test::Unit::TestCase
  fixtures :submissions

  def setup
    @controller = SubmissionsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @first_id = submissions(:first).id
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

    assert_not_nil assigns(:submissions)
  end

  def test_show
    get :show, :id => @first_id

    assert_response :success
    assert_template 'show'

    assert_not_nil assigns(:submission)
    assert assigns(:submission).valid?
  end

  def test_new
    get :new

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:submission)
  end

  def test_create
    num_submissions = Submission.count

    post :create, :submission => {}

    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_equal num_submissions + 1, Submission.count
  end

  def test_edit
    get :edit, :id => @first_id

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:submission)
    assert assigns(:submission).valid?
  end

  def test_update
    post :update, :id => @first_id
    assert_response :redirect
    assert_redirected_to :action => 'show', :id => @first_id
  end

  def test_destroy
    assert_nothing_raised {
      Submission.find(@first_id)
    }

    post :destroy, :id => @first_id
    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      Submission.find(@first_id)
    }
  end
end
