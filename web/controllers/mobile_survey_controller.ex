defmodule Ask.MobileSurveyController do
  use Ask.Web, :controller

  def index(conn, _params) do
    conn
    |> put_layout({Ask.LayoutView, "mobile_survey.html"})
    |> render("index.html", user: nil)
  end

  def get_step(conn, _params) do
    step_type = "multiple-choice"

    step = case step_type do
      "language-selection" ->
        %{
          id: "id",
          type: "language-selection",
          prompt: "Select a language",
          choices: ["English", "Spanish"]
        }
      "explanation" ->
        %{
          id: "id",
          type: "explanation",
          prompt: "This is an explanation step",
        }
      "multiple-choice" ->
        %{
          id: "id",
          type: "multiple-choice",
          prompt: "What's your favourite colour?",
          choices: ["Red", "Green", "Blue"]
        }
      "numeric" ->
        %{
          id: "id",
          type: "numeric",
          prompt: "What's your favourite number (1-10)?",
          min: 1,
          max: 10,
        }
    end

    render(conn, "show_step.json", step: step)
  end

  def send_reply(conn, %{"id" => _id, "value" => _value}) do
    conn
    |> put_status(:ok)
    |> text("OK")
  end
end