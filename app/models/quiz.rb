class Quiz < ApplicationRecord
  has_many :channel
  belongs_to :survey
  has_many :question
end
