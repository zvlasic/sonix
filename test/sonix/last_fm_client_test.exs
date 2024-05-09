defmodule Sonix.LastFmClientTest do
  use Sonix.DataCase, async: true
  alias Sonix.LastFmClient
  import Mox

  describe "Last FM client" do
    test "returns properly formed list" do
      expect(LastFmClient.Test, :user_top_artists, fn user, period ->
        assert user == "user"
        assert period == "overall"
        {:ok, [%{name: "name1", playcount: 1}, %{name: "name2", playcount: 3}]}
      end)

      {:ok, response} = LastFmClient.user_top_artists("user", "overall")
      assert response == [%{name: "name1", playcount: 1}, %{name: "name2", playcount: 3}]
    end

    test "returns proper error if username is wrong" do
      expect(LastFmClient.Test, :user_top_artists, fn _, _ -> {:error, "User not found"} end)
      {:error, response} = LastFmClient.user_top_artists("user", "overall")
      assert response == "User not found"
    end
  end
end
