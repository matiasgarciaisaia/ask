class AddCurrentQuestionToRespondent < ActiveRecord::Migration[5.0]
  def change
    add_reference :respondents, :current_question
  end
end
