defmodule Ask.Router do
  use Ask.Web, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", Ask do
    pipe_through :api
    resources "/quizzes", QuizzesController
  end
end
