class RemoveChannelsSurveysAndQuestionsFromQuizzes < ActiveRecord::Migration[5.0]
  def change
    remove_reference :quizzes, :survey
    remove_reference :quizzes, :channel
    remove_reference :quizzes, :question
  end
end
