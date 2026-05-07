defmodule CheckoutService do
  @moduledoc """
  Public API for the checkout service.
  """

  def new(_pricing_rules) do
    raise "not implemented"
  end

  def scan(_checkout, _product_code) do
    raise "not implemented"
  end

  def calculate(_checkout) do
    raise "not implemented"
  end
end
