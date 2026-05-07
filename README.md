# CheckoutService

An Elixir checkout service for supermarket pricing with configurable rules.

## Overview

This project implements a cashier service that manages shopping carts, applies pricing rules, and computes final totals. It supports three types of pricing rules:

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

**Key design decisions:**

- **Protocol-based extensibility** — New rule types can be added without touching existing code. Just define a struct and implement the `Rule` protocol.

- **First-match semantics** — Rules are evaluated in the order they are passed to `CheckoutService.new/2`. Only the first matching rule per product fires. This makes the system predictable and easy to reason about.

- **Pattern matching for product targeting** — Rules use function head pattern matching on `product_code` to efficiently reject non-matching products without conditionals.

- **Validated constructors** — Every rule has both `new/n` (returns `{:ok, rule} | {:error, reason}`) and `new!/n` (raises `ArgumentError`). Misconfiguration fails loudly at startup.

- **Money arithmetic via `ex_money`** — All prices and discounts are `Money.t()` structs, preventing floating-point errors. Fractional arithmetic uses `Decimal`.

### Example

```elixir
rules = [
  # Buy 1 get 1 free on green tea
  CheckoutService.Pricing.Rule.BuyXGetYFree.new!("GR1", 1, 1),
  # Strawberries drop to £4.50 when buying 3+
  CheckoutService.Pricing.Rule.BulkUnitPrice.new!("SR1", 3, Money.new(:GBP, "4.50"), Money.new(:GBP, "5.00")),
  # Coffee drops to 2/3 price when buying 3+
  CheckoutService.Pricing.Rule.BulkFractionPrice.new!("CF1", 3, {2, 3})
]

checkout = CheckoutService.new(rules)

checkout =
  checkout
  |> CheckoutService.scan!("GR1")
  |> CheckoutService.scan!("SR1")
  |> CheckoutService.scan!("GR1")
  |> CheckoutService.scan!("CF1")

receipt = CheckoutService.calculate(checkout)

receipt.total
# => #Money<:GBP, 19.66>

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

| Command | Description |
|---------|-------------|
| `mix check` | Run all checks (credo, dialyzer, tests) |
| `mix check --fix` | Auto-fix code style issues and formatting |
| `mix test` | Run the test suite (also runs as part of `mix check`) |
| `mix docs` | Generate documentation |
| `mix dialyzer` | Run static type analysis |
| `mix credo` | Run code quality checks |

### CI Pipeline

The project uses GitHub Actions for CI. The workflow runs `mix check` which includes:
- Code formatting verification
- Credo (code quality)
- Dialyzer (type analysis)
- Test suite
