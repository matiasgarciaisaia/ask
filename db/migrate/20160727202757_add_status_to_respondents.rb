class AddStatusToRespondents < ActiveRecord::Migration[5.0]
  def change
    add_column :respondents, :status, :integer
  end
end
