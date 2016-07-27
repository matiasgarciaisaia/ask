class Broker
  def call respondents, survey, channel
    respondents.each do |respondent|
      respondent.status = "running"
      respondent.save!
    end
  end
end
