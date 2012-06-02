require File.dirname(__FILE__) + '/../test_helper'

class ProblemTest < Test::Unit::TestCase
  fixtures :assignments, :problems

  def test_create_read_update_delete
    p1 = Problem.new
	p1.number = 1
	p1.description = "Find the Minimum"
	p1.assignment_id = 1
	
	p2 = Problem.new
	p2.number = 2
	p2.description = "Find the Last"
	p2.assignment_id = 1
	
	assert p1.save
	assert p2.save
	
	assert_equal p1.assignment, assignments(:one)
	assert_equal p2.assignment, assignments(:one)
	
	found_problem = Problem.find(p1.id)
	
	assert_equal p1.description, found_problem.description
	
	found_problem.number = 100
	
	assert found_problem.save
	
	assert found_problem.destroy
	
  end	

	
end
