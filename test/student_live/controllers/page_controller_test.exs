defmodule StudentLiveWeb.PageControllerTest do
  use StudentLiveWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Welcome to Student Portal"
  end
end
