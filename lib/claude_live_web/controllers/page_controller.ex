defmodule ClaudeLiveWeb.PageController do
  use ClaudeLiveWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
