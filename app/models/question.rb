class Question < ApplicationRecord
  belongs_to :quiz
  has_many :answers
  enum kind: { numeric: 0, text:1 }
end
