defmodule CheckoutService.Catalog.Product do
  @moduledoc "A product available for purchase, identified by a unique code."

  @type code :: String.t()

  @typedoc "A product registered in the catalog."
  @type t :: %__MODULE__{
          code: code(),
          name: String.t(),
          price: Money.t()
        }

  @enforce_keys [:code, :name, :price]
  defstruct [:code, :name, :price]
end
