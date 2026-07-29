defmodule StudentLiveWeb.PageController do
  use StudentLiveWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
