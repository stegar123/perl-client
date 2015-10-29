class PendingCombination < ActiveRecord::Base
  belongs_to :owner, :class_name => "User"
  belongs_to :combination
  belongs_to :new_device, :class_name => "Device"

  validates_presence_of :owner
  validates_presence_of :combination
  validates_presence_of :new_device
  validates_presence_of :new_version

end
