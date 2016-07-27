class Quiz < ApplicationRecord
  belongs_to :channel
  belongs_to :survey
  belongs_to :question
end
