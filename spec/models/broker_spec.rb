require 'rails_helper'

RSpec.describe Broker, type: :model do
  let(:broker) { Broker.new }
  let(:survey) { create(:survey) }
  let(:quiz) { survey.quiz }
  let(:channel) { create(:channel, quiz: quiz, method: :voice, settings: { verboice_channel_name: 'foo', verboice_project_id: '42' }) }
  let(:respondent) { create(:respondent, survey: survey) }
  it 'should call verboice with a callback_url' do
    stub_request(:get, channel.url).with(:body => {
      channel: 'foo',
      address: respondent.phone_number,
      callback_url: "http://localhost/broker/callback?respondent=#{respondent.id}",
      project_id: '42'
    }).to_return(:status => 200, :body => '', :headers => {})

    broker.call [respondent], survey, channel

    expect(Respondent.first.status).to eq('running')
  end
end
