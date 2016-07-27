class Scheduler
  def initialize broker
    @broker = broker
  end

  def start survey
    respondents = survey.respondents.to_a
    survey.quiz.methods.each do |method|
      batch = respondents.shift survey.quiz.batch_size
      @broker.call batch, survey, method
    end
  end
end
