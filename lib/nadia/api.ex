defmodule Nadia.API do
  @moduledoc """
  Provides basic functionalities for Telegram Bot API.
  """

  alias Nadia.Model.Error

  @default_timeout 5
  @base_url "https://api.telegram.org/bot"

  defp token, do: config_or_env(:token)
  defp recv_timeout, do: config_or_env(:recv_timeout) || @default_timeout

  defp config_or_env(key) do
    case Application.fetch_env(:nadia, key) do
      {:ok, {:system, var}} -> System.get_env(var)
      {:ok, {:system, var, default}} ->
        case System.get_env(var) do
          nil -> default
          val -> val
        end
      {:ok, value} -> value
      :error -> nil
    end
  end

  defp build_url(method), do: @base_url <> token() <> "/" <> method

  defp process_response(response, method) do
    case decode_response(response) do
      {:ok, true} -> :ok
      {:ok, result} -> {:ok, Nadia.Parser.parse_result(result, method)}
      %{ok: false, description: description} -> {:error, %Error{reason: description}}
      {:error, %HTTPoison.Error{reason: reason}} -> {:error, %Error{reason: reason}}
    end
  end

  defp decode_response(response) do
    with {:ok, %HTTPoison.Response{body: body}} <- response,
          %{result: result} <- Poison.decode!(body, keys: :atoms),
      do: {:ok, result}
  end

  defp build_multipart_request(params, file_field) do
    {file_path, params} = Keyword.pop(params, file_field)
    params = for {k, v} <- params, do: {to_string(k), v}
    {:multipart, params ++ [
      {:file, file_path,
       {"form-data", [{"name", to_string(file_field)}, {"filename", file_path}]}, []}
    ]}
  end

  defp build_request(params, file_field) do
    params = params
    |> Keyword.update(:reply_markup, nil, &(Poison.encode!(&1)))
    |> Enum.map(fn({k, v}) -> {k, drop_nil_fields(v)} end)

    if !is_nil(file_field) and File.exists?(params[file_field]) do
      build_multipart_request(params, file_field)
    else
      {:form, params}
    end
  end

  defp drop_nil_fields(params) when is_list(params) do
    params
    |> Enum.map(&drop_nil_fields/1)
    |> Poison.encode!
  end
  defp drop_nil_fields(params) when is_map(params) do
    params
    |> Map.from_struct
    |> Enum.filter_map(fn {_, v} -> v != nil end, fn {k, v} -> {k, drop_nil_fields(v)} end)
    |> Enum.into(%{})
  end
  defp drop_nil_fields(params), do: to_string(params)

  @doc """
  Generic method to call Telegram Bot API.

  Args:
  * `method` - name of API method
  * `options` - orddict of options
  * `file_field` - specify the key of file_field in `options` when sending files
  """
  def request(method, options \\ [], file_field \\ nil) do
    timeout = (Keyword.get(options, :timeout, 0) + recv_timeout()) * 1000
    method
    |> build_url
    |> HTTPoison.post(build_request(options, file_field), [], recv_timeout: timeout)
    |> process_response(method)
  end
end
