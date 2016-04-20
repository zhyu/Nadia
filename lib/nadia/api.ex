defmodule Nadia.API do
  @moduledoc """
  Provides basic functionalities for Telegram Bot API.
  """

  alias Nadia.Model.Error

  @default_timeout 5
  @base_url "https://api.telegram.org/bot"

  defp default_token, do: Application.get_env(:nadia, :token)
  defp recv_timeout, do: Application.get_env(:nadia, :recv_timeout, @default_timeout)

  defp build_url(method, token) do
    @base_url <> (token || default_token) <> "/" <> method
  end

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
    |> List.delete(:token)
    |> Keyword.update(:replmy_markup, nil, &(Poison.encode!(&1)))
    |> Enum.filter_map(fn {_, v} -> v end, fn {k, v} -> {k, to_string(v)} end)
    if !is_nil(file_field) and File.exists?(params[file_field]) do
      build_multipart_request(params, file_field)
    else
      {:form, params}
    end
  end

  @doc """
  Generic method to call Telegram Bot API.

  Args:
  * `method` - name of API method
  * `options` - orddict of options
  * `file_field` - specify the key of file_field in `options` when sending files
  """
  def request(method, options \\ [], file_field \\ nil) do
    timeout = (Keyword.get(options, :timeout, 0) + recv_timeout) * 1000
    {token, options} = Keyword.pop(options, :token)
    method
    |> build_url(token)
    |> HTTPoison.post(build_request(options, file_field), [], recv_timeout: timeout)
    |> process_response(method)
  end
end
