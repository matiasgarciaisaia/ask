class CreateQuizzes < ActiveRecord::Migration[5.0]
  def change
    create_table :quizzes do |t|
      t.string :name
      t.text :description
      t.references :channel, foreign_key: true
      t.references :survey, foreign_key: true
      t.references :question, foreign_key: true

      t.timestamps
    end
  end
end
