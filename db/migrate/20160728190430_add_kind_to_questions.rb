class AddKindToQuestions < ActiveRecord::Migration[5.0]
  def change
    add_column :questions, :kind, :integer, default: 0
  end
end
