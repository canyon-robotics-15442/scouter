defmodule ScouterWeb.PageController do
  use ScouterWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
