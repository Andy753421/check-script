require File.dirname(__FILE__) + '/../test_helper'

class TestcaseTest < Test::Unit::TestCase
  fixtures :problems, :testcases

  def test_create_read_update_delete
	t1 = Testcase.new
	t1.problem_id = 1
	t1.test_code = "(findMin (list 10 5 0 -10 -5))"
	t1.points = 2
	
	assert t1.save
	
	t2 = Testcase.new
	t2.problem_id = 1
	t2.test_code = "(findMin (list 0))"
	t2.points = 1
	
	assert t2.save

	assert_equal t1.problem_id, problems(:one).id
	assert_equal t2.problem_id, problems(:one).id
	
	found_tc = Testcase.find(t1.id)
	
	assert_equal found_tc.test_code, t1.test_code
	
	found_tc.maxtime = 100000
	
	assert found_tc.save
	
	assert t1.destroy
	assert t2.destroy
  end
  
end
