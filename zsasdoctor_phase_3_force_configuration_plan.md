# ⚙️ Phase 3: Force Reconfiguration (`-f / --force`)

## 1. Objective

Enable deterministic environment reset by:

- Removing incompatible or conflicting installations
- Reinstalling supported versions
- Rebinding environment variables cleanly

---

## 2. Design Principle

`--force` should not mean blind uninstall.

It should mean:

> Enforce a compliant state regardless of current system condition

---

## 3. CLI Design

### Commands

```bash
zsasdoctor config -f --java
zsasdoctor config -f --database
zsasdoctor config -f --ant
zsasdoctor config -f --auto
```

### Behavior Matrix

| Mode | Behavior |
|------|--------|
| Default | Fix only missing/misconfigured components |
| `-f` | Reinstall even if already present |

---

## 4. Execution Flow

```bash
1. Detect existing installation
2. Identify installation source (brew/manual/sdkman/etc.)
3. Prompt for confirmation (or skip with --yes)
4. Backup existing configurations (if applicable)
5. Uninstall cleanly
6. Install supported version
7. Update ~/.zshrc
8. Reload environment
9. Validate installation
```

---

## 5. Java Force Configuration

### Detection

```bash
java -version
/usr/libexec/java_home -V
```

### Decision Rules

| Condition | Action |
|----------|--------|
| Version not in 11–17 | Force reinstall |
| Version valid but not 17 | Replace with 17 |
| Multiple versions | Clean and standardize |

### Uninstall Strategy

| Source | Action |
|------|--------|
| Homebrew | `brew uninstall openjdk@*` |
| SDKMAN | `sdk uninstall java` |
| Manual | Remove from `/Library/Java/JavaVirtualMachines` |

### Install

```bash
brew install openjdk@17
```

### Environment Setup

```bash
export JAVA_HOME=$(/usr/libexec/java_home -v 17)
export PATH=$JAVA_HOME/bin:$PATH
```

### Validation

```bash
java -version
echo $JAVA_HOME
```

---

## 6. Database Force Configuration

### Strategy

- Prefer PostgreSQL
- Remove conflicting DBs only if required

### PostgreSQL Setup

```bash
brew uninstall postgresql@*
brew services stop postgresql
brew install postgresql@14
brew services start postgresql@14
```

### MySQL Setup

```bash
brew uninstall mysql
brew install mysql@8
```

### Environment Setup

```bash
export PATH="/opt/homebrew/opt/postgresql@14/bin:$PATH"
```

### Data Safety

```bash
echo "[WARNING] This will remove existing databases"
pg_dumpall > backup.sql
```

---

## 7. Ant Force Configuration

### Uninstall

```bash
brew uninstall ant
```

### Install

```bash
brew install ant
```

### Environment Setup

```bash
export ANT_HOME=$(brew --prefix ant)/libexec
export PATH=$ANT_HOME/bin:$PATH
```

### ant-props.jar Setup

```bash
cp ant-props.jar $ANT_HOME/lib/
# or
curl -o $ANT_HOME/lib/ant-props.jar <internal-url>
```

### Validation

```bash
ant -version
ls $ANT_HOME/lib/ant-props.jar
```

---

## 8. Auto Mode

```bash
zsasdoctor config -f --auto
```

### Execution Order

1. Java
2. Database
3. Ant
4. Intranet check

---

## 9. Safeguards

### Confirmation Prompt

```bash
This will remove existing installations. Continue? (y/n)
```

### Skip Prompt

```bash
--yes
```

### Backup

| Component | Action |
|----------|--------|
| Database | Dump before uninstall |
| ~/.zshrc | Backup before modification |

### Idempotency

Avoid duplicate entries:

```bash
grep -q "JAVA_HOME" ~/.zshrc || echo ...
```

---

## 10. Output Design

```bash
[FORCE] Java reconfiguration initiated
[INFO] Existing Java detected (v11)
[ACTION] Uninstalling...
[SUCCESS] Removed

[ACTION] Installing OpenJDK 17...
[SUCCESS] Installed

[ACTION] Updating ~/.zshrc
[SUCCESS] JAVA_HOME configured

[VALIDATION] Java version: 17 ✅
```

---

## 11. Risks & Mitigation

| Risk | Mitigation |
|------|-----------|
| Data loss | Backup before uninstall |
| Breaking other projects | User warning |
| Multiple package managers | Detect source |
| Permission issues | Use sudo fallback |

---

## 12. Enhancements

- `--dry-run` → preview actions
- `--profile bash|zsh`
- Version pinning via config file
- Project vs global setup

---

## 13. Key Positioning

Phase 3 transitions zsasdoctor from:

> Validator → Environment Orchestrator

To succeed, it must be:

- Predictable
- Safe
- Transparent

