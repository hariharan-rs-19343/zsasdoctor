# zsasdoctor

**SAS Developer Environment Doctor Tool** — validates and auto-configures your local development environment.

## Quick Start

```bash
# Make executable
chmod +x bin/zsasdoctor

# Run environment check
./bin/zsasdoctor check

# Auto-fix all issues
./bin/zsasdoctor config --auto
```

## Commands

| Command | Description |
|---------|-------------|
| `zsasdoctor check` | Validate local environment (Java, DB, Ant, Intranet) |
| `zsasdoctor config --auto` | Auto-fix all detected issues |
| `zsasdoctor config --java` | Install/configure Java 17 |
| `zsasdoctor config --database` | Install/configure PostgreSQL & MySQL |
| `zsasdoctor config --ant` | Install Apache Ant |
| `zsasdoctor config --intranet` | Show intranet connectivity guidance |
| `zsasdoctor version` | Print version |
| `zsasdoctor help` | Show usage information |

## Checks Performed

- **Java**: Installed, version 11–17, `JAVA_HOME` set in `~/.zshrc`
- **Database**: PostgreSQL ≥ 14 or MySQL 5–8
- **Ant**: Installed, on PATH, declared in shell profile
- **Intranet**: HTTP reachability, DNS resolution

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | All checks passed |
| 1 | Validation failed |
| 2 | Partial success (warnings) |
| 127 | Dependency missing |

## Install via Homebrew

```bash
brew tap your-org/tools
brew install zsasdoctor
```

## Run Tests

```bash
bash test/test_cases.sh
```

## Project Structure

```
zsasdoctor/
├── bin/zsasdoctor          # CLI entry point
├── lib/
│   ├── java.sh             # Java validation & fix
│   ├── database.sh         # PostgreSQL/MySQL validation & fix
│   ├── ant.sh              # Ant validation & fix
│   ├── intranet.sh         # Intranet connectivity
│   ├── utils.sh            # Shared helpers
│   └── logger.sh           # Coloured logging
├── config/constants.sh     # Version constraints & settings
├── install/brew_formula.rb # Homebrew formula
├── test/test_cases.sh      # Test suite
└── README.md
```
