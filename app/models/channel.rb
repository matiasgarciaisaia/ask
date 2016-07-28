class Channel < ApplicationRecord
  belongs_to :quiz
  enum method: [ :sms, :voice ]
  serialize :settings
end
