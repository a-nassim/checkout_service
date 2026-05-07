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
end
