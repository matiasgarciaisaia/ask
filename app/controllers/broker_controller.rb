class BrokerController < ApplicationController
  skip_before_action :verify_authenticity_token
  def callback
    respondent = Respondent.find(params[:respondent])
    render xml: Broker.new.answer_for(respondent, params)
  end
end
