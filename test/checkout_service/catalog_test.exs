defmodule CheckoutService.CatalogTest do
  use ExUnit.Case, async: true

  alias CheckoutService.Catalog
  alias CheckoutService.Catalog.Product

  describe "new/2" do
    test "builds a catalog from a currency and list of products" do
      product = %Product{code: "GR1", name: "Green tea", price: Money.new(:GBP, "3.11")}
      {:ok, catalog} = Catalog.new(:GBP, [product])
      assert {:ok, ^product} = Catalog.get(catalog, "GR1")
    end

    test "accepts an empty list" do
      {:ok, catalog} = Catalog.new(:GBP, [])
      assert {:error, :not_found} = Catalog.get(catalog, "GR1")
    end

    test "returns error when a product currency does not match" do
      product = %Product{code: "GR1", name: "Green tea", price: Money.new(:USD, "3.11")}
      assert {:error, :currency_mismatch} = Catalog.new(:GBP, [product])
    end

    test "last entry wins when product codes are duplicated" do
      v1 = %Product{code: "GR1", name: "Green tea", price: Money.new(:GBP, "3.11")}
      v2 = %Product{code: "GR1", name: "Green tea v2", price: Money.new(:GBP, "4.00")}
      {:ok, catalog} = Catalog.new(:GBP, [v1, v2])
      assert {:ok, ^v2} = Catalog.get(catalog, "GR1")
    end
  end

  describe "get/2" do
    setup do
      {:ok, catalog: Catalog.default()}
    end

    test "returns {:ok, product} for a known code", %{catalog: catalog} do
      assert {:ok, %Product{code: "GR1", name: "Green tea"}} = Catalog.get(catalog, "GR1")
    end

    test "returns {:error, :not_found} for an unknown code", %{catalog: catalog} do
      assert {:error, :not_found} = Catalog.get(catalog, "UNKNOWN")
    end
  end

  describe "default/0" do
    test "uses GBP as currency" do
      assert Catalog.default().currency == :GBP
    end

    test "contains GR1, SR1, and CF1 at the correct prices" do
      catalog = Catalog.default()
      gr1_price = Money.new(:GBP, "3.11")
      sr1_price = Money.new(:GBP, "5.00")
      cf1_price = Money.new(:GBP, "11.23")
      assert {:ok, %Product{code: "GR1", price: ^gr1_price}} = Catalog.get(catalog, "GR1")
      assert {:ok, %Product{code: "SR1", price: ^sr1_price}} = Catalog.get(catalog, "SR1")
      assert {:ok, %Product{code: "CF1", price: ^cf1_price}} = Catalog.get(catalog, "CF1")
    end
  end
end
