class RemoveUserPasswordAndUrlFromChannels < ActiveRecord::Migration[5.0]
  def change
    remove_column :channels, :user, :string
    remove_column :channels, :password, :string
    remove_column :channels, :url, :string
  end
end
