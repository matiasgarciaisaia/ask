class Quiz < ApplicationRecord
  has_many :channel
  has_one :survey
  has_many :question
end
