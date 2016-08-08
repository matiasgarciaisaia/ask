class AddSurveyToAnswers < ActiveRecord::Migration[5.0]
  def change
    add_reference :answers, :survey, foreign_key: true
  end
end
