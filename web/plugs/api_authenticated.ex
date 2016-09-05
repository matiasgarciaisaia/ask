defmodule Ask.Plugs.ApiAuthenticated do
  import Plug.Conn
  import Phoenix.Controller

  def init(default), do: default

  def call(conn, _) do
    conn = case Mix.env do
      :test ->
        test_user = conn.private[:test_user]
        conn |> put_session(:current_user, test_user)
      _ ->
        conn
    end

    case get_session(conn, :current_user) do
      nil -> conn |> put_status(:unauthorized) |> json(%{error: "Unauthorized"}) |> halt
      user -> assign(conn, :current_user, user)
    end
  end
end
