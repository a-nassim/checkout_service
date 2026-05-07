# CheckoutService

An Elixir checkout service for supermarket pricing with configurable rules.

## Overview

This project implements a cashier service that manages shopping carts, applies pricing rules, and computes final totals. It supports three pricing rules:

- **Buy X get Y free** — e.g. buy 1 get 1 free on green tea
- **Bulk unit price** — e.g. strawberries drop to £4.50 when buying 3+
- **Bulk fraction price** — e.g. coffee drops to 2/3 price when buying 3+

## Architecture

### Core Concepts

- **Catalog** — A lookup table of products keyed by product code, scoped to a single currency. The catalog is an explicit dependency, not global state, making it easy to swap for tests or multi-tenant scenarios.

- **Cart** — An accumulator of scanned product codes and their quantities.

- **Checkout** — A session struct holding a cart, pricing rules, and the catalog.

- **Receipt** — An auditable result containing line items, subtotal, discounts, and total.

### Pricing Rules

The pricing engine is built around the `CheckoutService.Pricing.Rule` protocol. Each rule is evaluated per product and returns a `Discount` if it applies, or `nil` if it does not.

The key design choices are:

- **Protocol-based extensibility** — New rule types can be added without touching existing code. Define a struct and implement the `Rule` protocol.
- **First-match semantics** — Rules are evaluated in the order passed to `CheckoutService.new/2`. Only the first matching rule per product applies, which keeps overlapping promotions predictable.
- **Money arithmetic via `ex_money`** — Prices, discounts, subtotals, and totals use `Money.t()` values instead of floats. Fractional discounts use `Decimal` under the hood and totals are rounded to the currency precision.

The checkout state is explicit as well: each session carries its cart, catalog, and pricing rules. That keeps the service free of global mutable state, easy to test, and ready for alternate catalogs or rule sets.

Receipts expose line items, subtotal, discounts, and total so pricing decisions can be inspected after calculation.

Rule constructors are validated and return either `{:ok, rule}` or `{:error, reason}`. The `new!/n` variants are convenient for startup-time configuration where invalid pricing rules should fail fast.

### Example

```elixir
catalog = CheckoutService.Catalog.default()
{:ok, %{price: sr1_price}} = CheckoutService.Catalog.get(catalog, "SR1")

rules = [
  # Buy 1 get 1 free on green tea
  CheckoutService.Pricing.Rule.BuyXGetYFree.new!("GR1", 1, 1),
  # Strawberries drop to £4.50 when buying 3+
  CheckoutService.Pricing.Rule.BulkUnitPrice.new!("SR1", 3, Money.new(:GBP, "4.50"), sr1_price),
  # Coffee drops to 2/3 price when buying 3+
  CheckoutService.Pricing.Rule.BulkFractionPrice.new!("CF1", 3, {2, 3})
]

checkout = CheckoutService.new(rules, catalog)

checkout =
  checkout
  |> CheckoutService.scan!("GR1")
  |> CheckoutService.scan!("CF1")
  |> CheckoutService.scan!("SR1")
  |> CheckoutService.scan!("CF1")
  |> CheckoutService.scan!("CF1")

receipt = CheckoutService.calculate(checkout)

receipt.total
# => #Money<:GBP, 30.57>

receipt.discounts
# => [%CheckoutService.Pricing.Discount{...}]
```

## Development

### Prerequisites

Install Elixir and Erlang using a version manager:

- **asdf**: Install via [asdf-vm.com](https://asdf-vm.com/)
- **mise**: Install via [mise.jdx.dev](https://mise.jdx.dev/)

The project uses the versions specified in `.tool-versions`:
- Elixir 1.19.5
- Erlang 28.5

### Setup

1. Install dependencies:

```bash
mix deps.get
```

2. Compile the project:

```bash
mix compile
```

### Development Commands

- `mix check` - Run formatting, Credo, Dialyzer, and the test suite.
- `mix test` - Run the test suite directly.
- `mix docs` - Generate documentation.

## Testing

### Acceptance Tests

The acceptance tests cover the four basket scenarios provided:

| Basket | Expected Total |
|--------|----------------|
| GR1,SR1,GR1,GR1,CF1 | £22.45 |
| GR1,GR1 | £3.11 |
| SR1,SR1,GR1,SR1 | £16.61 |
| GR1,CF1,SR1,CF1,CF1 | £30.57 |

### Additional Coverage

The test suite also covers:

- Rule validation and discount behavior for each pricing rule.
- Public checkout behavior such as scanning, unknown product handling, and empty baskets.
- Receipt calculation details such as line items, subtotals, discounts, first-match rule application, and rounding.
- Property tests for generated baskets, including non-negative totals, totals not exceeding subtotals, scan-order independence, and no-rule behavior.

## Adding New Pricing Rules

To add a new rule type:

1. Create a new module in `lib/checkout_service/pricing/rule/`
2. Define a struct with the required fields
3. Implement the `CheckoutService.Pricing.Rule` protocol

Example:

```elixir
defmodule CheckoutService.Pricing.Rule.MyNewRule do
  @enforce_keys [:product_code, :threshold]
  defstruct [:product_code, :threshold]

  defimpl CheckoutService.Pricing.Rule do
    def apply(rule, product, quantity) do
      # Return %CheckoutService.Pricing.Discount{...} if rule applies
      # Return nil otherwise
    end
  end
end
```
