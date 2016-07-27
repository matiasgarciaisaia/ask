require 'rails_helper'

RSpec.describe Scheduler, type: :model do
  let(:broker) { Broker.new }
  let(:scheduler) { Scheduler.new broker }
  let(:survey) { create(:survey) }
  it "should receive a start command with a sourvey and tell the broker to call the first respondent" do
    10.times { create(:respondent, survey: survey) }
    broker.should_receive(:call).twice
    scheduler.start survey
  end
end
