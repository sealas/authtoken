defmodule AuthToken.Plug do
  @moduledoc """
  Plugs for AuthToken

  ## Examples

      import AuthToken.Plug

      pipeline :auth do
        plug :verify_token
      end

      scope "/protected/route", MyApp do
        pipe_through :auth

        resources "/", DoNastyStuffController
      end
  """

  import Plug.Conn

  @doc """
  Checks authentication token from authorization header.

  If this fails, send 401 with message "error": "auth_fail" or "error": "timeout" as JSON
  """
  @spec verify_token(Plug.Conn.t, any) :: Plug.Conn.t
  def verify_token(conn, _options) do
    token_header = get_req_header(conn, "authorization") |> List.first

    crypto_token = if token_header, do: Regex.run(~r/(bearer\:? )?(.+)/, token_header) |> List.last

    case AuthToken.decrypt_token(crypto_token) do
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
    cond do
      AuthToken.is_timedout?(token) ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(:unauthorized, "{\"error\": \"timeout\"}")
        |> halt
      AuthToken.needs_refresh?(token) ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(:unauthorized, "{\"error\": \"needs_refresh\"}")
        |> halt
      true ->
        conn
    end
  end
end
