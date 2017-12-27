defmodule ConnCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with connections
      use Phoenix.ConnTest
    end
  end

  setup tags do
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
