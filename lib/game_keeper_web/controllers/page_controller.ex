defmodule GameKeeperWeb.PageController do
  use GameKeeperWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
