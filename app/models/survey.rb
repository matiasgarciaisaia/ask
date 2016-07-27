class Survey < ApplicationRecord
  belongs_to :quiz
  has_many :respondents
  enum status: [ :pending, :running, :completed ]

  def batch_size
    5
  end
end
