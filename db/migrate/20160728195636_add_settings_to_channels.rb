class AddSettingsToChannels < ActiveRecord::Migration[5.0]
  def change
    add_column :channels, :settings, :text
  end
end
