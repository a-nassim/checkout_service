defmodule CheckoutService.Catalog do
  @moduledoc """
  A lookup table of products keyed by product code.

  The catalog is an explicit dependency of a checkout session rather than
  global state, making it easy to swap in a custom catalog for tests or
  multi-tenant scenarios.

      catalog = CheckoutService.Catalog.new([%Product{code: "GR1", ...}])
      checkout = CheckoutService.new(rules, catalog)
  """

  alias CheckoutService.Catalog.Product

  @typedoc "A catalog mapping product codes to products."
  @type t :: %__MODULE__{
          products: %{Product.code() => Product.t()}
        }

  @enforce_keys [:products]
  defstruct [:products]

  @doc "Builds a catalog from a list of `Product` structs."
  @spec new([Product.t()]) :: t()
  def new(products) when is_list(products) do
    index = Map.new(products, fn %Product{code: code} = product -> {code, product} end)
    %__MODULE__{products: index}
  end

  @doc """
  Looks up a product by code.

  Returns `{:ok, product}` if found, `{:error, :not_found}` otherwise.
  """
  @spec get(t(), Product.code()) :: {:ok, Product.t()} | {:error, :not_found}
  def get(%__MODULE__{products: products}, code) do
    case Map.fetch(products, code) do
      {:ok, product} -> {:ok, product}
      :error -> {:error, :not_found}
    end
  end

  @doc "Returns the standard catalog pre-loaded with the three known products."
  @spec default() :: t()
  def default do
    new([
      %Product{code: "GR1", name: "Green tea", price: Money.new(:GBP, "3.11")},
      %Product{code: "SR1", name: "Strawberries", price: Money.new(:GBP, "5.00")},
      %Product{code: "CF1", name: "Coffee", price: Money.new(:GBP, "11.23")}
    ])
  end
end
