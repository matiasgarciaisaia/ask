class Scheduler
  def initialize
    @broker = Broker.new
  end

  def start survey
    respondents = survey.respondents.to_a
    survey.status = "running"
    survey.save!
    batch = respondents.shift survey.batch_size
    @broker.call batch, survey, survey.channel
  end
end
