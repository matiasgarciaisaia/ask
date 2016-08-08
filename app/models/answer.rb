class Answer < ApplicationRecord
  belongs_to :respondent
  belongs_to :question
  belongs_to :survey
end
