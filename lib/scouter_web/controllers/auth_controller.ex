defmodule ScouterWeb.AuthController do
  use ScouterWeb, :controller
  plug Ueberauth

  def request(conn, _params) do
    send_resp(conn, 400, "Unknown provider")
  end

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    conn
    |> put_session(:current_user, %{email: auth.info.email, name: auth.info.name})
    |> put_flash(:info, "Signed in as #{auth.info.email}")
    |> redirect(to: ~p"/")
  end

  def callback(%{assigns: %{ueberauth_failure: _fails}} = conn, _params) do
    conn
    |> put_flash(:error, "Could not authenticate.")
    |> redirect(to: ~p"/")
  end

  def logout(conn, _params) do
    conn
    |> configure_session(drop: true)
    |> redirect(to: ~p"/")
  end
end