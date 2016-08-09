defmodule Ask.Quiz do
  use Ask.Web, :model

  schema "quizzes" do
    field :name
    field :description
    timestamps(inserted_at: :created_at)
  end
end
