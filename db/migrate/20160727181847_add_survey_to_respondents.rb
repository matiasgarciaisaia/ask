class AddSurveyToRespondents < ActiveRecord::Migration[5.0]
  def change
    add_reference :respondents, :survey, foreign_key: true
  end
end
