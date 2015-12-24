defmodule RabbitCICore.Step do
  use RabbitCICore.Web, :model
  alias RabbitCICore.Log
  alias RabbitCICore.Build
  alias RabbitCICore.Log
  alias RabbitCICore.Repo
  alias RabbitCICore.Step
  alias RabbitCICore.BuildUpdaterChannel

  after_insert :notify_chan
  after_update :notify_chan

  def notify_chan(changeset) do
    id = changeset.model.build_id
    BuildUpdaterChannel.update_build(id)
    changeset
  end

  schema "steps" do
    field :status, :string
    field :name, :string
    has_many :logs, Log
    # TODO: artifacts
    belongs_to :build, Build
    timestamps
  end

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    cast(model, params, ~w(build_id name status), ~w())
    |> validate_inclusion(:status, ["queued", "running", "failed", "finished"])
  end

  def log(_step, _clean \\ :clean)
  def log(step, :clean), do: clean_log log(step, :no_clean)
  def log(step, :no_clean) do
    from(l in assoc(step, :logs),
         order_by: [asc: l.order],
         select: l.stdio)
    |> Repo.all
    |> Enum.join
  end

  def clean_log(raw_log) do
    Regex.replace(~r/\x1b(\[[0-9;]*[mK])?/, raw_log, "")
  end

  # This is for use in BuildMan.Vagrant. You can use it, but you probably
  # shouldn't as it uses step_id instead of a %Step{}.
  def update_status!(step_id, status) do
    Repo.get!(Step, step_id)
    |> Step.changeset(%{status: status})
    |> Repo.update!
  end
end
