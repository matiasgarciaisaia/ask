class CreateQuizzes < ActiveRecord::Migration[5.0]
  def change
    create_table :quizzes do |t|
      t.string :name
      t.text :description
      t.references :channel
      t.references :survey
      t.references :question

      t.timestamps
    end
  end
end
