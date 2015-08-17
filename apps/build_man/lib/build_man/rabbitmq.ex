defmodule BuildMan.RabbitMQ do
  use Supervisor
  use AMQP
  require Logger

  @pool_size 5
  @conn_pool_name Module.concat(__MODULE__, ConnPool)
  @pub_pool_name Module.concat(__MODULE__, PubPool)

  @moduledoc """
  This code was adapted from pma/phoenix_pubsub_rabbitmq which can be found on
  GitHub.
  """

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(opts) do
    Logger.info("BuildMan.RabbitMQ started!")

    conn_pool_opts = [
      name: {:local, @conn_pool_name},
      worker_module: BuildMan.RabbitMQConn,
      size: opts[:pool_size] || @pool_size,
      strategy: :fifo,
      max_overflow: 0
    ]

    pub_pool_opts = [
      name: {:local, @pub_pool_name},
      worker_module: BuildMan.RabbitMQPub,
      size: opts[:pool_size] || @pool_size,
      max_overflow: 0
    ]

    children = [
      :poolboy.child_spec(@conn_pool_name, conn_pool_opts, opts),
      :poolboy.child_spec(@pub_pool_name, pub_pool_opts, @conn_pool_name),
    ]

    supervise(children, strategy: :one_for_one)
  end

  def with_conn(fun) when is_function(fun, 1) do
    case get_conn(0, @pool_size) do
      {:ok, conn}      -> fun.(conn)
      {:error, reason} -> {:error, reason}
    end
  end

  defp get_conn(retry_count, max_retry_count) do
    case :poolboy.transaction(@conn_pool_name, &GenServer.call(&1, :conn)) do
      {:ok, conn}      -> {:ok, conn}
      {:error, _reason} when retry_count < max_retry_count ->
        get_conn(retry_count + 1, max_retry_count)
      {:error, reason} -> {:error, reason}
    end
  end

  def publish(exchange, routing_key, payload, options \\ []) do
    case get_chan(0, @pool_size) do
      {:ok, chan}      -> Basic.publish(chan, exchange, routing_key, payload,
                                        options)
      {:error, reason} -> {:error, reason}
    end
  end

  defp get_chan(retry_count, max_retry_count) do
    case :poolboy.transaction(@pub_pool_name, &GenServer.call(&1, :chan)) do
      {:ok, chan}      -> {:ok, chan}
      {:error, _reason} when retry_count < max_retry_count ->
        get_chan(retry_count + 1, max_retry_count)
      {:error, reason} -> {:error, reason}
    end
  end
end
