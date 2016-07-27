class Quiz < ApplicationRecord
  has_many :channels
  has_one :survey
  has_many :questions
end
