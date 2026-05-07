defmodule CheckoutService.Cldr do
  @moduledoc false
  use Cldr,
    default_locale: "en",
    providers: [Cldr.Number, Money]
end
