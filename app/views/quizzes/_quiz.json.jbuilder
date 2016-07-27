json.extract! quiz, :id, :name, :description, :channel_id, :survey_id, :question_id, :created_at, :updated_at
json.url quiz_url(quiz, format: :json)