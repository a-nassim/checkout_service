# CheckoutService

An Elixir checkout service.

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
