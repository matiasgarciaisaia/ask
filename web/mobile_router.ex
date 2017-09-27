defmodule Ask.MobileRouter do
  use Ask.Web, :router

  get "/mobile_survey/:respondent_id", Ask.MobileSurveyController, :index
  get "/mobile_survey/get_step/:respondent_id", Ask.MobileSurveyController, :get_step
  post "/mobile_survey/send_reply/:respondent_id", Ask.MobileSurveyController, :send_reply
  get "/mobile_survey/errors/unauthorized", Ask.MobileSurveyController, :unauthorized_error
end
