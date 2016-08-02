class Respondent < ApplicationRecord
  belongs_to :survey
  belongs_to :current_question, class_name: "Question", optional: true
  has_many :answers
  enum status: [ :pending, :running, :completed, :failed ]

  def answer_of(question)
    answers.where(question_id: question.id).first
  end
end
