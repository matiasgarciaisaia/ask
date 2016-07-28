class Question < ApplicationRecord
  belongs_to :quiz
  enum kind: { numeric: 0, text:1 }
end
