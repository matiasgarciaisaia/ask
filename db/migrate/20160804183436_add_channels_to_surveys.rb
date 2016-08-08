class AddChannelsToSurveys < ActiveRecord::Migration[5.0]
  def change
    add_reference :surveys, :channel, foreign_key: true
  end
end
