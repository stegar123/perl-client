require 'test_helper'

class PendingCombinationTest < ActiveSupport::TestCase
  test "pending combination creation" do
    assert_raise ActiveRecord::RecordInvalid do
      PendingCombination.create!(:new_version => "5.5")
    end
    
    assert PendingCombination.create!(:new_device => Device.first, :new_version => "test", :combination => Combination.first, :owner => User.first)
  end
end
