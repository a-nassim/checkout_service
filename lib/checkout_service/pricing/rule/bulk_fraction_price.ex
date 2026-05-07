defmodule CheckoutService.Pricing.Rule.BulkFractionPrice do
  @moduledoc """
  Bulk fraction price rule applied when a quantity threshold is met.

  When the quantity of a product meets or exceeds `threshold`, the price per
  unit drops to `pay_fraction` of the original price for all units. The `pay_fraction`
  represents the proportion of the price you *pay* — e.g. `{2, 3}` means you
  pay 2/3 of the original price (a 1/3 discount).

  The pay_fraction must be between 0 and 1 exclusive.

  Use `new/3` to construct a validated rule.

  Example — coffee drops to 2/3 of its price when buying 3 or more:

      {:ok, rule} = BulkFractionPrice.new("CF1", 3, {2, 3})
  """

  alias CheckoutService.Catalog.Product
  alias CheckoutService.Pricing

  @enforce_keys [:product_code, :threshold, :pay_fraction]
  defstruct [:product_code, :threshold, :pay_fraction]

  @type t :: %__MODULE__{
          product_code: Product.code(),
          threshold: pos_integer(),
          pay_fraction: Decimal.t()
        }

  @doc """
  Builds a validated `BulkFractionPrice` rule.

  `pay_fraction` is a `{numerator, denominator}` tuple representing the target
  fraction of the initial price that should be paid, and must resolve to
  a value strictly between 0 and 1.

  Returns `{:error, :invalid_threshold}` if `threshold` is not a positive
  integer, or `{:error, :invalid_fraction}` if the fraction is out of range.
  """
  @spec new(Product.code(), pos_integer(), {pos_integer(), pos_integer()}) ::
          {:ok, t()} | {:error, :invalid_threshold} | {:error, :invalid_fraction}
  def new(product_code, threshold, {numerator, denominator})
      when is_integer(threshold) and threshold > 0 and
             is_integer(numerator) and is_integer(denominator) and denominator > 0 do
    pay_fraction = Decimal.div(numerator, denominator)

    if Decimal.compare(pay_fraction, 0) == :gt and Decimal.compare(pay_fraction, 1) == :lt do
      {:ok,
       %__MODULE__{product_code: product_code, threshold: threshold, pay_fraction: pay_fraction}}
    else
      {:error, :invalid_fraction}
    end
  end

  def new(_product_code, threshold, {numerator, denominator})
      when is_integer(threshold) and threshold > 0 and
             is_integer(numerator) and is_integer(denominator) do
    {:error, :invalid_fraction}
  end

  def new(_product_code, _threshold, _pay_fraction), do: {:error, :invalid_threshold}

  @doc "Like `new/3` but raises `ArgumentError` on invalid configuration."
  @spec new!(Product.code(), pos_integer(), {pos_integer(), pos_integer()}) :: t()
  def new!(product_code, threshold, pay_fraction) do
    case new(product_code, threshold, pay_fraction) do
      {:ok, rule} ->
        rule

      {:error, :invalid_threshold} ->
        raise ArgumentError,
              "BulkFractionPrice rule misconfigured for #{product_code}: " <>
                "threshold must be a positive integer, got #{inspect(threshold)}"

      {:error, :invalid_fraction} ->
        raise ArgumentError,
              "BulkFractionPrice rule misconfigured for #{product_code}: " <>
                "fraction must be between 0 and 1 exclusive, got #{inspect(pay_fraction)}"
    end
  end

  defimpl Pricing.Rule do
    alias CheckoutService.Pricing.Discount
    alias CheckoutService.Pricing.Rule.BulkFractionPrice

    def apply(
          %BulkFractionPrice{
            product_code: product_code,
            threshold: threshold,
            pay_fraction: pay_fraction
          } = rule,
          %Product{code: product_code, price: initial_price} = product,
          quantity
        )
        when quantity >= threshold do
      amount = initial_price |> Money.mult!(Decimal.sub(1, pay_fraction)) |> Money.mult!(quantity)
      %Discount{rule: rule, product: product, amount: amount}
    end

    def apply(_rule, _product, _quantity), do: nil
  end
end
