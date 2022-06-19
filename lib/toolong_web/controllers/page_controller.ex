defmodule ToolongWeb.PageController do
  use ToolongWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
