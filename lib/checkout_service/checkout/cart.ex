defmodule CheckoutService.Checkout.Cart do
  @moduledoc "A shopping cart mapping scanned product codes to their quantities."

  alias CheckoutService.Catalog.Product

  @type quantity :: pos_integer()

  @typedoc "A shopping cart accumulating scanned products and quantities."
  @type t :: %__MODULE__{
          items: %{Product.code() => quantity()}
        }

  defstruct items: %{}
end
