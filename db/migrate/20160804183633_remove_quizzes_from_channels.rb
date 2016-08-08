class RemoveQuizzesFromChannels < ActiveRecord::Migration[5.0]
  def change
    remove_reference :channels, :quiz, foreign_key: true
  end
end
