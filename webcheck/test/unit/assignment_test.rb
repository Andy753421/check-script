require File.dirname(__FILE__) + '/../test_helper'

class AssignmentTest < Test::Unit::TestCase
  fixtures :assignments

  def test_create_read_update_delete
    as1 = Assignment.new
	as1.name = "assignment 3"
	as1.maxtime = 10
	as1.available = "2008-03-01"
	as1.due = "2008-03-31"
	as1.comparator_id = 0
	as1.visible = false
	
    assert as1.save

    found_assignment = Assignment.find(as1.id)

    assert_equal as1.name, found_assignment.name

    found_assignment.name = "assignment 4"

    assert found_assignment.save

    assert found_assignment.destroy
  end
end
