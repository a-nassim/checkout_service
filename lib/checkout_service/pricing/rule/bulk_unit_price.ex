defmodule CheckoutService.Pricing.Rule.BulkUnitPrice do
  @moduledoc """
  Bulk unit price rule.

  When the quantity of a product meets or exceeds `threshold`, the price per
  unit drops to `price` for all units. The discount is the difference between
  the original and bulk price, multiplied by the quantity.

  Use `new/3` to construct a validated rule, or the struct literal when the
  values are guaranteed correct (e.g. compile-time constants).

  Example — strawberries drop to £4.50 when buying 3 or more:

      {:ok, rule} = BulkUnitPrice.new("SR1", 3, Money.new(:GBP, "4.50"), Money.new(:GBP, "5.00"))
  """

  alias CheckoutService.Catalog.Product
  alias CheckoutService.Pricing

  @enforce_keys [:product_code, :threshold, :price]
  defstruct [:product_code, :threshold, :price]

  @type t :: %__MODULE__{
          product_code: Product.code(),
          threshold: pos_integer(),
          price: Money.t()
        }

  @doc """
  Builds a validated `BulkUnitPrice` rule.

  Returns `{:error, :price_not_discounted}` if `bulk_price` is not strictly
  less than `catalog_price`.
  """
  @spec new(Product.code(), pos_integer(), Money.t(), Money.t()) ::
          {:ok, t()} | {:error, :invalid_threshold} | {:error, :price_not_discounted}
  def new(product_code, threshold, bulk_price, catalog_price)
      when is_integer(threshold) and threshold > 0 do
    if Money.compare(bulk_price, catalog_price) == :lt do
      {:ok, %__MODULE__{product_code: product_code, threshold: threshold, price: bulk_price}}
    else
      {:error, :price_not_discounted}
    end
  end

  def new(_product_code, _threshold, _bulk_price, _catalog_price),
    do: {:error, :invalid_threshold}

  @doc "Like `new/4` but raises `ArgumentError` on invalid configuration."
  @spec new!(Product.code(), pos_integer(), Money.t(), Money.t()) :: t()
  def new!(product_code, threshold, bulk_price, catalog_price) do
    case new(product_code, threshold, bulk_price, catalog_price) do
      {:ok, rule} ->
        rule

      {:error, :invalid_threshold} ->
        raise ArgumentError,
              "BulkUnitPrice rule misconfigured for #{product_code}: " <>
                "threshold must be a positive integer, got #{inspect(threshold)}"

      {:error, :price_not_discounted} ->
        raise ArgumentError,
              "BulkUnitPrice rule misconfigured for #{product_code}: " <>
                "bulk price #{bulk_price} must be less than catalog price #{catalog_price}"
    end
  end

  defimpl Pricing.Rule do
    alias CheckoutService.Pricing.Discount
    alias CheckoutService.Pricing.Rule.BulkUnitPrice

    def apply(
          %BulkUnitPrice{product_code: product_code, threshold: threshold, price: target_price} =
            rule,
          %Product{code: product_code, price: initial_price} = product,
          quantity
        )
        when quantity >= threshold do
      amount = initial_price |> Money.sub!(target_price) |> Money.mult!(quantity)
      %Discount{rule: rule, product: product, amount: amount}
    end

    def apply(_rule, _product, _quantity), do: nil
  end
end
