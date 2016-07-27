class AddUserPasswordUrlAndMethodToChannels < ActiveRecord::Migration[5.0]
  def change
    add_column :channels, :user, :string
    add_column :channels, :password, :string
    add_column :channels, :url, :string
    add_column :channels, :method, :integer
  end
end
