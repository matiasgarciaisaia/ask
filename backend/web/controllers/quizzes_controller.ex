defmodule Ask.QuizzesController do
  use Ask.Web, :controller
  alias Ask.Quiz

  def index(conn, _params) do
    quizzes = Repo.all(Quiz)
    json conn, quizzes
  end

  def show(conn, %{"id" => id}) do
    user = Repo.get!(Quiz, id)
    json conn, user
  end
end
