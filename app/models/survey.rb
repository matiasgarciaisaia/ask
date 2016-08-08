class Survey < ApplicationRecord
  belongs_to :quiz
  belongs_to :channel
  has_many :respondents
  has_many :answers
  enum status: [:pending, :running, :completed]

  def batch_size
    5
  end
end
