class PendingCombination < ActiveRecord::Base
  belongs_to :owner, :class_name => "User"
  belongs_to :combination
  belongs_to :new_device, :class_name => "Device"
end
