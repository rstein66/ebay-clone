defmodule Renaissance.Test.AuctionsTest do
  use Renaissance.DataCase
  alias Renaissance.{Auctions, Users, Repo}

  @valid_end %{
    day: "15",
    hour: "14",
    minute: "3",
    month: "4",
    year: "3019"
  }

  @auction_one %{
    "title" => "Test Title",
    "description" => "Test description.",
    "end_auction_at" => @valid_end,
    "price" => "10.00"
  }

  def fixture(:user) do
    user_params = %{email: "test@suite.com", password: "password"}
    {:ok, user} = Users.register_user(user_params)
    user
  end

  @auction_two %{
    "title" => "Test Title Two",
    "description" => "Test description two.",
    "end_auction_at" => @valid_end,
    "price" => "15.00"
  }

  describe "auctions" do
    test "stores a valid auction in the db" do
      seller_id = fixture(:user).id
      {:ok, auction_created} = Auctions.create_auction(seller_id, @auction_one)

      assert auction_created.title == @auction_one["title"]
      assert auction_created.description == @auction_one["description"]
      assert Money.compare(auction_created.price, Money.new(10_00)) == 0
    end

    test "does not store when title is blank" do
      seller_id = fixture(:user).id

      invalid_params = Map.put(@auction_two, "title", "")
      Auctions.create_auction(seller_id, invalid_params)

      count = Repo.aggregate(Ecto.Query.from(p in "auctions"), :count, :id)
      assert 0 == count
    end

    test "does not store when invalid seller_id" do
      seller_id = fixture(:user).id
      invalid_seller_id = seller_id * 7 - 1

      exception =
        assert_raise Ecto.ConstraintError, fn ->
          Auctions.create_auction(invalid_seller_id, @auction_two)
        end

      assert exception.message =~ "foreign_key_constraint"
    end

    test "returns an index of auctions when logged in" do
      seller_id = fixture(:user).id
      {:ok, first} = Auctions.create_auction(seller_id, @auction_one)
      {:ok, second} = Auctions.create_auction(seller_id, @auction_two)

      count = Repo.aggregate(Ecto.Query.from(p in "auctions"), :count, :id)
      assert 2 == count

      assert first.title == @auction_one["title"]
      assert first.description == @auction_one["description"]
      assert first.price == Money.new(10_00)

      assert second.title == @auction_two["title"]
      assert second.description == @auction_two["description"]
      assert second.price == Money.new(15_00)
    end

    test "updates a pre-existing auction description" do
      seller_id = fixture(:user).id
      {:ok, auction} = Auctions.create_auction(seller_id, @auction_one)

      auction_id = auction.id
      updated_description = "Updated"

      Auctions.update_description(auction_id, %{"description" => updated_description})

      retrieved_auction = Auctions.get(auction_id)
      assert retrieved_auction.description == updated_description
    end
  end
end
