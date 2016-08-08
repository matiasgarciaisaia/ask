class Channel < ApplicationRecord
  belongs_to :user
  has_many :surveys
  enum method: [ :sms, :voice ]
  serialize :settings
end
