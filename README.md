# zsasdoctor

**SAS Developer Environment Doctor Tool** — validates, auto-configures, and force-reinstalls your local development environment.

## Quick Start

```bash
# Make executable
chmod +x bin/zsasdoctor

# Run environment check
./bin/zsasdoctor check

# Auto-fix all issues
./bin/zsasdoctor config --auto

# Force reinstall everything (skip prompts)
./bin/zsasdoctor config -f --yes --auto
```

## Commands

| Command | Description |
|---------|-------------|
| `zsasdoctor check` | Validate local environment (Java, DB, Ant, Intranet) |
| `zsasdoctor config --auto` | Auto-fix all detected issues |
| `zsasdoctor config --java` | Install/configure Java 17 |
| `zsasdoctor config --database` | Install/configure PostgreSQL or MySQL |
| `zsasdoctor config --ant` | Install Apache Ant |
| `zsasdoctor config --intranet` | Show intranet connectivity guidance |
| `zsasdoctor config -f --auto` | Force reinstall all components |
| `zsasdoctor config -f --java` | Force reinstall Java |
| `zsasdoctor config -f --database` | Force reinstall database |
| `zsasdoctor config -f --ant` | Force reinstall Ant |
| `zsasdoctor version` | Print version |
| `zsasdoctor help` | Show usage information |

## Flags

| Flag | Description |
|------|-------------|
| `-f`, `--force` | Force reinstall even if already present |
| `--yes` | Skip confirmation prompts (use with `-f`) |

## Checks Performed

- **Java**: Installed, version 11–17, `JAVA_HOME` set in `~/.zshrc`
- **Database**: PostgreSQL ≥ 14 or MySQL 5–8
- **Ant**: Installed, on PATH, declared in shell profile
- **Intranet**: File download via `wget` (credentials from `~/.wgetrc`)

## Force Mode (`-f`)

Force mode performs a full teardown and reinstall cycle:

1. Detect existing installation and source (Homebrew / SDKMAN / manual)
2. Prompt for confirmation (skip with `--yes`)
3. Backup `~/.zshrc` → `~/.zshrc.zsasdoctor.bak`
4. Backup database data (PostgreSQL: `pg_dumpall`)
5. Uninstall existing version
6. Clean old environment variables from `~/.zshrc`
7. Install supported version via Homebrew
8. Set fresh environment variables in `~/.zshrc`
9. Validate the new installation

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
