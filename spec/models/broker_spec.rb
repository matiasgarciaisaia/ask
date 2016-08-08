require 'rails_helper'

RSpec.describe Broker, type: :model do
  let(:broker) { Broker.new }
  let(:survey) { create(:survey, channel: channel) }
  let(:quiz) { survey.quiz }
  let(:channel) { create(:channel, method: :voice) }
  let(:respondent) { create(:respondent, survey: survey) }

  it 'should call verboice with a callback_url' do
    stub_request(:get, channel.settings[:verboice_url]).with(:body => {
      channel: 'foo',
      address: respondent.phone_number,
      callback_url: "http://localhost/broker/callback?respondent=#{respondent.id}",
      project_id: '42'
    }).to_return(:status => 200, :body => '', :headers => {})

    broker.call [respondent], survey, channel

    expect(Respondent.first.status).to eq('running')
  end
end
