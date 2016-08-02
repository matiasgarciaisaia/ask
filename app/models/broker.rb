class Broker
  def call(respondents, survey, channel)
    respondents.each do |respondent|
      respondent.status = "running"
      respondent.save!
      if channel.voice?
        request = RestClient::Request.new(
          url: channel.url,
          method: :get,
          user: channel.user,
          password: channel.password,
          payload: {
            channel: channel.settings[:verboice_channel_name],
            address: respondent.phone_number,
            callback_url: callback_url_for(respondent),
            project_id: channel.settings[:verboice_project_id]
          }
        )
        request.execute
      end
    end

  end
  def base_url
    case Rails.env
    when 'development'
      tunnels = JSON.parse RestClient.get('http://ngrok:4040/api/tunnels').body
      tunnels['tunnels'].first['public_url']
    when 'test'
      'http://localhost'
    else
      ENV['BASE_URL']
    end
  end

  def callback_url_for(respondent)
    "#{base_url}/broker/callback?respondent=#{respondent.id}"
  end

  def answer_from(respondent, params)
    quiz = respondent.survey.quiz
    respondent.answers.create!(text: params['Digits'], question: respondent.current_question) if respondent.current_question
    respondent.current_question = if respondent.current_question.nil?
      quiz.questions.first
    else
      questions = quiz.questions.to_a
      questions[questions.index(respondent.current_question) + 1]
    end
    respondent.save!
    if respondent.current_question.nil?
      respondent.status = 'completed'
      respondent.save!
      "<Response><Hangup/></Response>"
    else
      "<Response><Gather action='#{callback_url_for(respondent)}'><Say>#{respondent.current_question.text}</Say></Gather></Response>"
    end
  end
end
