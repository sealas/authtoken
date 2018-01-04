defmodule AuthToken do
  @moduledoc """
  Simplified encrypted authentication tokens using JWE.

  Configuration needed:

    config :authtoken,
      token_key: PUT_KEY_HERE

  Generate a token for your user after successful authentication like this:

  ## Examples

      token_content = %{userid: user.id}

      token = AuthToken.generate_token(token_content)
  """

  @doc """
  Generates an encrypted auth token.

  Contains an encoded version of the provided map, plus a timestamp for timeout.
  """
  @spec generate_token(map) :: String.t
  def generate_token(user_data) do
    token_content = %{ct: DateTime.to_unix(DateTime.utc_now())} |> Enum.into(user_data)

    jwt = JOSE.JWT.encrypt(get_jwk(), get_jwe(), token_content) |> JOSE.JWE.compact |> elem(1)

    # Remove JWT header
    Regex.run(~r/.+?\.(.+)/, jwt) |> List.last
  end

  @doc """
  Generate a random key for AES128

  ## Examples

      iex> AuthToken.generate_key()
      {:ok, <<153, 67, 252, 211, 199, 186, 212, 114, 109, 99, 222, 205, 31, 26, 100, 253>>}
  """
  @spec generate_key() :: {:ok, binary}
  def generate_key do
    {:ok, :crypto.strong_rand_bytes(16)}
  end

  @doc """
  Decrypt an authentication token

  Format "bearer: tokengoeshere" will be accepted and parsed out.
  """
  @spec decrypt_token(String.t) :: {:ok, String.t} | {:error}
  def decrypt_token(headless_token) when is_binary(headless_token) do
    header = get_jwe() |> JOSE.Poison.lexical_encode! |> :base64url.encode

    auth_token = header <> "." <> headless_token

    try do
      %{fields: token} = JOSE.JWT.decrypt(get_jwk(), auth_token) |> elem(1)

      {:ok, token}
    rescue
      _ -> {:error}
    end
  end

  @spec decrypt_token(nil) :: {:error}
  def decrypt_token(_) do
    {:error}
  end

  @spec get_jwe() :: %{alg: String.t, enc: String.t, typ: String.t}
  defp get_jwe do
    %{ "alg" => "dir", "enc" => "A128GCM", "typ" => "JWT" }
  end

  @spec get_jwk() :: %JOSE.JWK{}
  defp get_jwk do
    get_config(:token_key)
    |> JOSE.JWK.from_oct()
  end

  @spec get_config(atom) :: %{}
  def get_config(atom) do
    content = Application.get_env(:authtoken, atom)

    unless content, do: raise "No AuthToken configuration set for " <> atom

    content
  end
end
