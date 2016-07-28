class Scheduler
  def initialize
    @broker = Broker.new
  end

  def start survey
    respondents = survey.respondents.to_a
    survey.status = "running"
    survey.save!
    survey.quiz.channels.each do | channel |
      batch = respondents.shift survey.batch_size
      @broker.call batch, survey, channel
    end
  end
end
