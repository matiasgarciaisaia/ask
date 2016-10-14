defmodule Ask.SurveyController do
  use Ask.Web, :api_controller

  alias Ask.Project
  alias Ask.Channel
  alias Ask.Survey

  def index(conn, %{"project_id" => project_id}) do
    surveys = Project
    |> Repo.get!(project_id)
    |> authorize(conn)
    |> assoc(:surveys)
    |> preload(:channels)
    |> Repo.all

    render(conn, "index.json", surveys: surveys)
  end

  def create(conn, %{"project_id" => project_id}) do
    changeset = Project
    |> Repo.get!(project_id)
    |> authorize(conn)
    |> build_assoc(:surveys)
    |> Survey.changeset(%{project_id: project_id, name: ""})

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

  def show(conn, %{"project_id" => project_id, "id" => id}) do
    survey = Project
    |> Repo.get!(project_id)
    |> authorize(conn)
    |> assoc(:surveys)
    |> Repo.get!(id)
    |> Repo.preload([:channels])
    |> with_respondents_count

    render(conn, "show.json", survey: survey)
  end

  def update(conn, %{"project_id" => project_id, "id" => id, "survey" => survey_params}) do
    changeset = Project
    |> Repo.get!(project_id)
    |> authorize(conn)
    |> assoc(:surveys)
    |> Repo.get!(id)
    |> Repo.preload([:channels])
    |> with_respondents_count
    |> change
    |> update_channels(survey_params)
    |> Survey.changeset(survey_params)
    |> Survey.update_state

    case Repo.update(changeset) do
      {:ok, survey} ->
        render(conn, "show.json", survey: survey)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(Ask.ChangesetView, "error.json", changeset: changeset)
    end
  end

  defp update_channels(changeset, %{"channels" => channels_params}) do
    channels_changeset = Enum.map(channels_params, fn ch ->
      Repo.get!(Channel, ch) |> change
    end)

    changeset
    |> put_assoc(:channels, channels_changeset)
  end

  defp update_channels(changeset, _) do
    changeset
  end

  defp with_respondents_count(survey) do
    respondents_count = survey |> assoc(:respondents) |> select(count("*")) |> Repo.one
    %{survey | respondents_count: respondents_count}
  end

  def delete(conn, %{"project_id" => project_id, "id" => id}) do
    Project
    |> Repo.get!(project_id)
    |> authorize(conn)
    |> assoc(:surveys)
    |> Repo.get!(id)
    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    |> Repo.delete!

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
