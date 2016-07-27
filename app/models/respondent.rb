class Respondent < ApplicationRecord
  belongs_to :survey
  enum status: [ :pending, :running, :completed, :failed ]
end
