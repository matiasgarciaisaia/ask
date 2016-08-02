require 'rails_helper'

RSpec.describe BrokerController, type: :controller do
  let(:quiz) { respondent.survey.quiz }
  let!(:question) { create(:question, quiz: quiz) }
  let(:respondent) { create(:respondent, status: 'running') }

  it "answers verboice callback with the text of the first question" do
    post :callback, params: {respondent: respondent.id}
    respondent.reload

    expect(response.body).to eq("<Response><Gather action='http://localhost/broker/callback?respondent=#{respondent.id}'><Say>#{question.text}</Say></Gather></Response>")
    expect(respondent.status).to eq('running')
    expect(respondent.current_question).to eq(question)

    post :callback, params: {respondent: respondent.id, 'Digits' => '123' }
    respondent.reload

    expect(response.body).to eq("<Response><Hangup/></Response>")
    expect(respondent.status).to eq('completed')
    expect(respondent.current_question).to be_nil
    expect(respondent.answer_of(question).text).to eq('123')
  end
end
