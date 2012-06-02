require File.dirname(__FILE__) + '/../test_helper'
require 'comparators_controller'

# Re-raise errors caught by the controller.
class ComparatorsController; def rescue_action(e) raise e end; end

class ComparatorsControllerTest < Test::Unit::TestCase
  fixtures :comparators

  def setup
    @controller = ComparatorsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @first_id = comparators(:first).id
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

    assert_not_nil assigns(:comparators)
  end

  def test_show
    get :show, :id => @first_id

    assert_response :success
    assert_template 'show'

    assert_not_nil assigns(:comparator)
    assert assigns(:comparator).valid?
  end

  def test_new
    get :new

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:comparator)
  end

  def test_create
    num_comparators = Comparator.count

    post :create, :comparator => {}

    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_equal num_comparators + 1, Comparator.count
  end

  def test_edit
    get :edit, :id => @first_id

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:comparator)
    assert assigns(:comparator).valid?
  end

  def test_update
    post :update, :id => @first_id
    assert_response :redirect
    assert_redirected_to :action => 'show', :id => @first_id
  end

  def test_destroy
    assert_nothing_raised {
      Comparator.find(@first_id)
    }

    post :destroy, :id => @first_id
    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      Comparator.find(@first_id)
    }
  end
end
