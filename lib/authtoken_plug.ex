defmodule AuthToken.Plug do
  @moduledoc """
  Plugs for AuthToken
  """

  import Plug.Conn

  @doc """
  Checks authentication token from authorization header.

  If this fails, send 401 with message "error": "auth_fail" or "error": "timeout" as JSON
  """
  @spec verify_token(Plug.Conn.t, any) :: Plug.Conn.t
  def verify_token(conn, _options) do
    crypto_token = get_req_header(conn, "authorization")

    case AuthToken.decrypt_token(List.first(crypto_token)) do
      {:error} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(:unauthorized, "{\"error\": \"auth_fail\"}")
        |> halt
      {:ok, token} ->
        conn |> check_token_time(token)
    end
  end

  @spec check_token_time(Plug.Conn.t, map) :: Plug.Conn.t
  defp check_token_time(conn, token) do
    timeout = AuthToken.get_config(:timeout)

    {:ok, ct} = DateTime.from_unix(token["ct"])

    cond do
      DateTime.diff(DateTime.utc_now(), ct) > timeout ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(:unauthorized, "{\"error\": \"timeout\"}")
        |> halt
      true ->
        conn
    end
  end
end
