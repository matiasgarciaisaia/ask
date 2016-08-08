class Quiz < ApplicationRecord
  belongs_to :user
  has_one :survey
  has_many :questions
end
