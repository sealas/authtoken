defmodule AuthTokenTest do
  use ConnCase

  @user %{id: 123}

  describe "tokens" do
    test "token generation" do
      token = AuthToken.generate_token(@user)

      assert {:ok, user} = AuthToken.decrypt_token(token)
      assert user["id"] == @user.id
    end
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

    test "denying access for expired token", %{conn: conn} do
      token = AuthToken.generate_token(@user)

      assert Application.get_env(:authtoken, :timeout) == 86400

      Application.put_env(:authtoken, :timeout, -1)

      assert Application.get_env(:authtoken, :timeout) == -1

      conn = conn
      |> put_req_header("authorization", "bearer: " <> token)
      |> AuthToken.Plug.verify_token([])

      assert json_response(conn, 401) == %{"error" => "timeout"}
    end

    test "granting access for correct token", %{conn: conn} do
      token = AuthToken.generate_token(@user)

      conn = conn
      |> put_req_header("authorization", "bearer: " <> token)
      |> AuthToken.Plug.verify_token([])

      assert conn.status != 401
    end
  end
end
