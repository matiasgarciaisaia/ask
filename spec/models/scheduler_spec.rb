require 'rails_helper'

class Survey
  def initialize quiz, respondents
  end
end

class Quiz
  def methods
    [:sms, :voice]
  end
  def batch_size
    5
  end
end

RSpec.describe Scheduler, type: :model do
  let(:broker) { Broker.new }
  let(:scheduler) { Scheduler.new broker }
  it "should receive a start command with a sourvey and tell the broker to call the first respondent" do
    10.times { create(:respondent) }
    broker.should_receive(:call).twice
    scheduler.start_survey_for Quiz.new, Respondent.all
  end
end
