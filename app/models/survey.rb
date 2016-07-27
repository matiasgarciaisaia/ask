class Survey < ApplicationRecord
  belongs_to :quiz
  has_many :respondents
end
