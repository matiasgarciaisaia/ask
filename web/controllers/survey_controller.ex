defmodule Ask.SurveyController do
  use Ask.Web, :api_controller

  alias Ask.Survey
  alias Ask.Respondent
  alias Ask.Channel

  def index(conn, %{"project_id" => project_id}) do
    surveys = Repo.all(from s in Survey, where: s.project_id == ^project_id, preload: [:channels])
    render(conn, "index.json", surveys: surveys)
  end

  def create(conn, %{"project_id" => project_id}) do
    changeset = Survey.changeset(%Survey{}, %{project_id: project_id, name: "Untitled"})

    case Repo.insert(changeset) do
      {:ok, survey} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", project_survey_path(conn, :show, project_id, survey))
        |> render("show.json", survey: survey |> Repo.preload([:channels]))
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(Ask.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    survey = Repo.get!(Survey, id) |> Repo.preload([:channels])
    respondents_count = Repo.one(from r in Respondent, select: count("*"), where: r.survey_id == ^survey.id)
    survey = %{survey | respondents_count: respondents_count}
    render(conn, "show.json", %{survey: survey})
  end

  def update(conn, %{"id" => id, "survey" => survey_params}) do
    prev_survey = Repo.get!(Survey, id) |> Repo.preload([:channels])
    changeset = Survey.changeset(prev_survey, survey_params)
    case Repo.update(changeset) do
      {:ok, survey} ->
        respondents_count = Repo.one(from r in Respondent, select: count("*"), where: r.survey_id == ^survey.id)
        case survey_params["channels"] do
          [ channel | _ ] -> update_channels(conn, channel, survey, respondents_count)
          _ ->
            survey = %{survey | respondents_count: respondents_count}
            render(conn, "show.json", survey: survey)
        end
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(Ask.ChangesetView, "error.json", changeset: changeset)
    end
  end

  defp update_channels(conn, channel, survey, respondents_count) do
    channel_id  = channel["channelId"]
    channel = Repo.get!(Channel, channel_id)
    channels_changeset = Enum.map([channel], &Ecto.Changeset.change/1)
    case (survey |> Ecto.Changeset.change |> Ecto.Changeset.put_assoc(:channels, channels_changeset) |> Repo.update) do
      {:ok, updated_survey} ->
        render(conn, "show.json", survey: %{updated_survey | respondents_count: respondents_count})
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(Ask.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    survey = Repo.get!(Survey, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(survey)

    send_resp(conn, :no_content, "")
  end

  def launch(conn, %{"survey_id" => id}) do
    survey = Repo.get!(Survey, id) |> Repo.preload([:channels])
    changeset = Survey.changeset(survey, %{"state": "running"})
    case Repo.update(changeset) do
      {:ok, survey} ->
        render(conn, "show.json", survey: survey)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(Ask.ChangesetView, "error.json", changeset: changeset)
    end
  end
end
