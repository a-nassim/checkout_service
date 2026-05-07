defmodule CheckoutService.Checkout.Cart do
  @moduledoc "A shopping cart mapping scanned product codes to their quantities."

  alias CheckoutService.Catalog.Product

  @type quantity :: pos_integer()

  @typedoc "A shopping cart accumulating scanned products and quantities."
  @type t :: %__MODULE__{
          items: %{Product.code() => quantity()}
        }

  defstruct items: %{}

  @spec add(t(), Product.code()) :: t()
  def add(%__MODULE__{} = cart, product_code) do
    %{cart | items: Map.update(cart.items, product_code, 1, &(&1 + 1))}
  end

  @spec remove(t(), Product.code()) :: {:ok, t()} | {:error, :not_in_cart}
  def remove(%__MODULE__{} = cart, product_code) do
    case Map.fetch(cart.items, product_code) do
      {:ok, 1} ->
        {:ok, %{cart | items: Map.delete(cart.items, product_code)}}

      {:ok, quantity} ->
        {:ok, %{cart | items: Map.put(cart.items, product_code, quantity - 1)}}

      :error ->
        {:error, :not_in_cart}
    end
  end

  @spec clear(t()) :: t()
  def clear(%__MODULE__{}), do: %__MODULE__{}
end
