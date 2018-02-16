defmodule AuthTokenTest do
  use ConnCase, async: true
  import ExUnitProperties

  @user %{id: 123}

  defp gen_authtoken_key() do
    gen_ticker = fn _ ->
      StreamData.constant(AuthToken.generate_key())
    end

    StreamData.constant(:unused)
    |> StreamData.bind(gen_ticker)
    |> StreamData.unshrinkable()
  end

  defp gen_usermap() do
    StreamData.fixed_map(%{ id: StreamData.integer() })
  end

  defp gen_authtoken_token(user) do
    gen_ticker = fn user ->
      StreamData.constant(AuthToken.generate_token(user))
    end

    StreamData.constant(user)
    |> StreamData.bind(gen_ticker)
    |> StreamData.unshrinkable()
  end

  defp gen_authtoken_stale_token(user) do
    gen_ticker = fn user ->
      StreamData.constant(AuthToken.generate_token(user))
    end

    StreamData.constant(user)
    |> StreamData.bind(gen_ticker)
    |> StreamData.unshrinkable()
  end

  defp reset_timeout_env() do
    Application.put_env(:authtoken, :timeout, 86400)
    Application.put_env(:authtoken, :refresh, 1800)
  end

  setup do
    reset_timeout_env()
  end

  describe "keys" do
    property "generate_key/0 returns a valid AES128 key" do
      check all authtoken_key <- gen_authtoken_key() do
        {:ok, key} = authtoken_key
        assert byte_size(key) == 16
      end
    end
  end

  describe "unique keys" do
    property "generate_key/0 always returns a unique AES128 key" do
      # n.b.: not using `check all` here, since that would require we we
      # construct a StreamData list. but all we want to do is ensure a large list is unique
      authtoken_keys = Enum.take(gen_authtoken_key(), 99_999)

      assert authtoken_keys == Enum.uniq(authtoken_keys)
    end
  end

  describe "token properties (and life-cycle)" do
    property "generate_token/1 and decrypt_token/1 are reversible" do
      check all user <- gen_usermap(),
        authtoken_token <- gen_authtoken_token(user) do

        {:ok, encrypted_token} = authtoken_token
        assert {:ok, token} = AuthToken.decrypt_token(encrypted_token)
        assert token["id"] == user.id
      end
    end

    property "authtoken can timeout" do
      check all user <- gen_usermap(),
        authtoken_token <- gen_authtoken_token(user) do

        reset_timeout_env()

        {:ok, encrypted_token} = authtoken_token
        {:ok, token} = AuthToken.decrypt_token(encrypted_token)

        refute AuthToken.is_timedout?(token)
        refute AuthToken.needs_refresh?(token)

        Application.put_env(:authtoken, :timeout, -1)
        Application.put_env(:authtoken, :refresh, -1)

        assert AuthToken.is_timedout?(token)
        assert AuthToken.needs_refresh?(token)
      end
    end

    # property "token refresh" do
    #   check all user <- gen_usermap(),
    #     authtoken_token <- gen_authtoken_token(user) do

    #     reset_timeout_env()

    #     {:ok, encrypted_token} = authtoken_token
    #     {:ok, token} = AuthToken.decrypt_token(encrypted_token)

    #     assert AuthToken.refresh_token(token) == {:error, :stillfresh}
    #     assert AuthToken.refresh_token(encrypted_token) == {:error, :stillfresh}

    #     :timer.sleep(1000)

    #     Application.put_env(:authtoken, :refresh, -1)
    #     assert {:ok, fresh_token} = AuthToken.refresh_token(token)
    #     assert {:ok, fresh_token} = AuthToken.refresh_token(encrypted_token)

    #     {:ok, token} = AuthToken.decrypt_token(fresh_token)
    #     assert token["ct"] < token["rt"]

    #     Application.put_env(:authtoken, :timeout, -1)
    #     assert AuthToken.refresh_token(token) == {:error, :timedout}
    #   end
    # end
  end

  describe "plug verifying and testing tokens" do
    test "denying access for no token", %{conn: conn} do
      conn = AuthToken.Plug.verify_token(conn, [])

      assert json_response(conn, 401)
    end

    test "denying access for wrong token", %{conn: conn} do
      conn = conn
      |> put_req_header("authorization", "bearer: ")
      |> AuthToken.Plug.verify_token([])

      assert json_response(conn, 401)
    end

    test "denying access for stale and expired token", %{conn: conn} do
      {:ok, token} = AuthToken.generate_token(@user)

      Application.put_env(:authtoken, :refresh, -1)

      conn = conn
      |> put_req_header("authorization", "bearer: " <> token)
      |> AuthToken.Plug.verify_token([])

      assert json_response(conn, 401) == %{"error" => "needs_refresh"}

      Application.put_env(:authtoken, :timeout, -1)

      conn = conn
      |> recycle()
      |> put_req_header("authorization", "bearer: " <> token)
      |> AuthToken.Plug.verify_token([])

      assert json_response(conn, 401) == %{"error" => "timeout"}
    end

    test "granting access for correct token", %{conn: conn} do
      {:ok, token} = AuthToken.generate_token(@user)

      conn = conn
      |> put_req_header("authorization", "bearer: " <> token)
      |> AuthToken.Plug.verify_token([])

      assert conn.status != 401

      conn = conn
      |> put_req_header("authorization", "bearer " <> token)
      |> AuthToken.Plug.verify_token([])

      assert conn.status != 401
    end
  end
end
