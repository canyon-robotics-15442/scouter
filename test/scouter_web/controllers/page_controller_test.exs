defmodule ScouterWeb.PageControllerTest do
  use ScouterWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Scouter"
  end
end
