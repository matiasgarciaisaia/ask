require 'rails_helper'

RSpec.describe Scheduler, type: :model do
  let(:scheduler) { Scheduler.new }
  let(:survey) { create(:survey) }
  let(:quiz) { survey.quiz }
  it "should receive a start command with a survey and tell the broker to call the first respondent" do
    create(:channel, quiz: quiz, method: :sms)
    create(:channel, quiz: quiz, method: :voice)
    10.times { create(:respondent, survey: survey) }
    expect(survey).to receive(:batch_size).twice.and_return(5)
    scheduler.start survey

    expect(survey.status).to eq("running")
    expect(Respondent.first.status).to eq("running")
  end
end
