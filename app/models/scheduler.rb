class Scheduler
  def initialize broker
    @broker = broker
  end

  def start_survey_for quiz, respondents
    survey = Survey.new quiz, respondents
    quiz.methods.each do |method|
      batch = respondents.to_a.shift quiz.batch_size
      @broker.call batch, survey, method
    end
  end
end
