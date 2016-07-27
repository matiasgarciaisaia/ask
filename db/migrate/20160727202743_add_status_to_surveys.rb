class AddStatusToSurveys < ActiveRecord::Migration[5.0]
  def change
    add_column :surveys, :status, :integer
  end
end
