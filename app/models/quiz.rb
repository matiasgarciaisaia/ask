class Quiz < ApplicationRecord
  has_many :channel
  has_one :survey
  has_many :question

  def methods
    [:sms, :voice]
  end
  
  def batch_size
    5
  end
end
