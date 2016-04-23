defmodule RabbitCICore.JobTest do
  use RabbitCICore.ModelCase
  import RabbitCICore.Factory

  alias RabbitCICore.Job

  @valid_attrs %{status: "queued", step_id: -1}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Job.changeset(%Job{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Job.changeset(%Job{}, @invalid_attrs)
    refute changeset.valid?
    assert {:status, "can't be blank"} in changeset.errors
  end

  test "changeset with valid status" do
    for status <- ["queued", "running", "failed", "finished", "error"] do
      attrs = %{@valid_attrs | status: status}
      changeset = Job.changeset(%Job{}, attrs)
      assert Ecto.Changeset.get_field(changeset, :status) == status
      assert changeset.valid?
    end
  end

  test "changeset with invalid status" do
    for status <- ["bacon", "turtles", "sandwich"] do
      attrs = %{@valid_attrs | status: status}
      changeset = Job.changeset(%Job{}, attrs)
      refute changeset.valid?
      assert {:status, "is invalid"} in changeset.errors
    end
  end

  test "changeset without step is invalid" do
    changeset = Job.changeset(%Job{}, @valid_attrs)
    assert {:error, changeset} = Repo.insert changeset
    refute changeset.valid?
    assert {:step_id, "does not exist"} in changeset.errors
  end

  test "changeset with step is valid" do
    step = create(:step)
    attrs = put_in(@valid_attrs.step_id, step.id)
    changeset = Job.changeset(%Job{}, attrs)
    assert {:ok, _model} = Repo.insert changeset
  end

  test "Job.update_status!/2 should update the status of a job" do
    for status <- ["queued", "running", "failed", "finished", "error"] do
      job = create(:job)
      updated_job = Job.update_status!(job.id, status)
      assert updated_job.status == status
    end
  end

  test "Job.log/2 :no_clean" do
    job = create(:job)

    for str <- ~w(foo bar baz) do
      stdio = IO.ANSI.format([:bright, :red, str]) |> to_string
      # Make sure that the string we start with contains ANSI escape codes.
      assert String.contains?(stdio, "\e[31m")
      create(:log, %{stdio: stdio, job: job})
    end

    assert Job.log(job, :no_clean) ==
      "\e[1m\e[31mfoo\e[0m\e[1m\e[31mbar\e[0m\e[1m\e[31mbaz\e[0m"
  end

  test "Job.log/2 :clean" do
    job = create(:job)

    for str <- ~w(foo bar baz) do
      stdio = IO.ANSI.format([:bright, :red, str]) |> to_string
      # Make sure that the string we start with contains ANSI escape codes.
      assert String.contains?(stdio, "\e[31m")
      create(:log, %{stdio: stdio, job: job})
    end

    assert Job.log(job, :clean) == "foobarbaz"
  end
end