defmodule CheckoutService.Pricing.Rule.BuyXGetYFree do
  @moduledoc """
  Buy X get Y free pricing rule.

  For every `buy_amount + free_amount` units scanned, `free_amount` units are
  free. The discount is applied once per complete cycle.

  Use `new/3` to construct a validated rule.

  Example — BOGO (buy 1 get 1 free):

      {:ok, rule} = BuyXGetYFree.new("GR1", 1, 1)

  With 4 items scanned: 2 complete cycles → 2 free items.
  """

  alias CheckoutService.Catalog.Product
  alias CheckoutService.Pricing

  @enforce_keys [:product_code, :buy_amount, :free_amount]
  defstruct [:product_code, :buy_amount, :free_amount]

  @type t :: %__MODULE__{
          product_code: Product.code(),
          buy_amount: pos_integer(),
          free_amount: pos_integer()
        }

  @doc """
  Builds a validated `BuyXGetYFree` rule.

  Returns `{:error, :invalid_amounts}` if either `buy_amount` or `free_amount`
  is not a positive integer.
  """
  @spec new(Product.code(), pos_integer(), pos_integer()) ::
          {:ok, t()} | {:error, :invalid_amounts}
  def new(product_code, buy_amount, free_amount)
      when is_integer(buy_amount) and buy_amount > 0 and
             is_integer(free_amount) and free_amount > 0 do
    {:ok,
     %__MODULE__{product_code: product_code, buy_amount: buy_amount, free_amount: free_amount}}
  end

  def new(_product_code, _buy_amount, _free_amount), do: {:error, :invalid_amounts}

  @doc "Like `new/3` but raises `ArgumentError` on invalid configuration."
  @spec new!(Product.code(), pos_integer(), pos_integer()) :: t()
  def new!(product_code, buy_amount, free_amount) do
    case new(product_code, buy_amount, free_amount) do
      {:ok, rule} ->
        rule

      {:error, :invalid_amounts} ->
        raise ArgumentError,
              "BuyXGetYFree rule misconfigured for #{product_code}: " <>
                "buy_amount and free_amount must be positive integers, " <>
                "got buy_amount=#{inspect(buy_amount)}, free_amount=#{inspect(free_amount)}"
    end
  end

  defimpl Pricing.Rule do
    alias CheckoutService.Pricing.Discount
    alias CheckoutService.Pricing.Rule.BuyXGetYFree

    def apply(
          %BuyXGetYFree{
            product_code: product_code,
            buy_amount: buy_amount,
            free_amount: free_amount
          } = rule,
          %Product{code: product_code} = product,
          quantity
        ) do
      free_units = div(quantity, buy_amount + free_amount) * free_amount

      if free_units > 0 do
        %Discount{rule: rule, product: product, amount: Money.mult!(product.price, free_units)}
      end
    end

    def apply(_rule, _product, _quantity), do: nil
  end
end
