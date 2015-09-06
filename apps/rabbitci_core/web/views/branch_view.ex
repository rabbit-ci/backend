defmodule RabbitCICore.BranchView do
  use RabbitCICore.Web, :view

  alias RabbitCICore.BranchSerializer

  def render("index.json", %{conn: conn, branches: branches}) do
    BranchSerializer.format(branches, conn, %{})
  end
end
