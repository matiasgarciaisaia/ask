class Respondent < ApplicationRecord
  belongs_to :survey
  belongs_to :current_question, class_name: "Question", optional: true
  enum status: [ :pending, :running, :completed, :failed ]
end
