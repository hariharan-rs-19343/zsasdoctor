# 📦 Project Plan: `zsasdoctor`

## 1. Objective

Develop a CLI diagnostic and auto-configuration tool (`zsasdoctor`) to:

- Validate a developer’s local environment for SAS product development
- Enforce version constraints and system readiness
- Provide automated remediation (install/configure dependencies)
- Be easily installable via **Homebrew**

---

## 2. Scope Definition

### Core Capabilities

| Capability | Description |
|----------|-------------|
| Environment Validation | Check system readiness (Java, DB, Ant, Network) |
| Version Enforcement | Ensure strict compatibility constraints |
| Auto Fix | Install / configure missing or incompatible dependencies |
| Developer Guidance | Provide actionable output with fixes |
| Brew Distribution | Installable via `brew install zsasdoctor` |

---

## 3. CLI Design

### Command Structure

```bash
zsasdoctor check
zsasdoctor config --auto
zsasdoctor config --java
zsasdoctor config --database
zsasdoctor config --ant
zsasdoctor config --intranet
zsasdoctor version
zsasdoctor help
```

### Exit Codes

| Code | Meaning |
|------|--------|
| 0 | All checks passed |
| 1 | Validation failed |
| 2 | Partial success |
| 127 | Dependency missing |

---

## 4. Architecture Design

### Script Type
- POSIX-compliant shell (prefer **bash** for portability)
- Modular scripts (avoid monolithic design)

### Folder Structure

```bash
zsasdoctor/
│
├── bin/
│   └── zsasdoctor             # Entry point
│
├── lib/
│   ├── java.sh
│   ├── database.sh
│   ├── ant.sh
│   ├── intranet.sh
│   ├── utils.sh
│   └── logger.sh
│
├── config/
│   └── constants.sh
│
├── install/
│   └── brew_formula.rb
│
├── test/
│   └── test_cases.sh
│
└── README.md
```

---

## 5. Phase 1: System Checks

### 5.1 Java Validation

**Requirements:**
- Installed
- Version: `11 ≤ version ≤ 17`
- Recommended: `17`
- `$JAVA_HOME` present in `~/.zshrc`

**Validation Logic:**
```bash
java -version
echo $JAVA_HOME
grep "JAVA_HOME" ~/.zshrc
```

**Failure Cases:**
- Java not installed
- Version < 11 or > 17
- JAVA_HOME missing

---

### 5.2 Database Validation

#### PostgreSQL (Preferred)
- Version: `> 14`

```bash
psql --version
```

#### MySQL
- Version: `5 ≤ version ≤ 8`
- Recommended: `8`

```bash
mysql --version
```

**Failure Rules:**
- PostgreSQL < 14 → Fail
- MySQL < 5 or > 8 → Fail

---

### 5.3 Ant Validation

**Requirements:**
- Installed
- Available in PATH
- Ideally declared in `~/.zshrc`

```bash
ant -version
which ant
```

---

### 5.4 Intranet Connectivity

**Validation Strategy:**
- Ping internal host
- Attempt file download (critical)

```bash
curl -I <internal-url>
wget <internal-file>
```

**Pass Criteria:**
- Successful HTTP response
- File download works

---

## 6. Phase 2: Auto Configuration

### Command: `zsasdoctor config`

#### Modes

| Command | Action |
|--------|--------|
| `--auto` | Run all fixes |
| `--java` | Install/configure Java |
| `--database` | Install/configure DB |
| `--ant` | Install/configure Ant |
| `--intranet` | Configure access |

---

### 6.1 Java Fix

- Install via Homebrew:
```bash
brew install openjdk@17
```

- Update `.zshrc`:
```bash
export JAVA_HOME=$(/usr/libexec/java_home -v 17)
export PATH=$JAVA_HOME/bin:$PATH
```

---

### 6.2 Database Fix

#### PostgreSQL:
```bash
brew install postgresql@14
brew services start postgresql@14
```

#### MySQL:
```bash
brew install mysql@8
```

---

### 6.3 Ant Fix

```bash
brew install ant
```

---

### 6.4 Intranet Fix

- Validate VPN / internal DNS
- Provide actionable message (cannot auto-fix fully)

---

## 7. Logging & Output Design

### Output Format

```bash
[INFO] Checking Java...
[SUCCESS] Java 17 detected
[WARNING] JAVA_HOME not set
[ERROR] MySQL version unsupported
```

### Color Coding

| Type | Color |
|------|------|
| SUCCESS | Green |
| WARNING | Yellow |
| ERROR | Red |

---

## 8. Homebrew Distribution

### Step 1: Create Formula

**File:** `zsasdoctor.rb`

```ruby
class Zsasdoctor < Formula
  desc "SAS Developer Environment Doctor Tool"
  homepage "https://your-repo-url"
  url "https://github.com/your-org/zsasdoctor/archive/v1.0.0.tar.gz"
  sha256 "<SHA256_HASH>"

  def install
    bin.install "bin/zsasdoctor"
    lib.install Dir["lib/*"]
  end

  test do
    system "#{bin}/zsasdoctor", "version"
  end
end
```

---

### Step 2: Tap Repository

```bash
brew tap your-org/tools
brew install zsasdoctor
```

---

## 9. Testing Strategy

### Test Types

| Type | Description |
|------|-------------|
| Unit | Each module (java.sh, db.sh) |
| Integration | Full system validation |
| Negative | Missing dependencies |
| Version Edge Cases | Boundary versions |

---

## 10. Error Handling Strategy

- Graceful fallback
- No abrupt script exits unless critical
- Aggregated reporting

---

## 11. Security Considerations

- Avoid executing untrusted scripts
- Validate URLs before download
- Use HTTPS only
- Avoid exposing internal endpoints in logs

---

## 12. Milestones

| Phase | Deliverable | Timeline |
|------|------------|---------|
| Phase 1 | Check commands | Week 1 |
| Phase 2 | Auto config | Week 2 |
| Phase 3 | Logging + UX | Week 3 |
| Phase 4 | Brew packaging | Week 4 |
| Phase 5 | Testing & Release | Week 5 |

---

## 13. Future Enhancements

- Plugin-based checks
- YAML config for rules
- Cross-platform support (Linux/Windows via WSL)
- GUI wrapper
- CI validation mode

---

## 14. Example Execution

```bash
$ zsasdoctor check

[INFO] Java Check
[SUCCESS] Java 17 installed
[WARNING] JAVA_HOME missing

[INFO] Database Check
[ERROR] PostgreSQL not found

[INFO] Ant Check
[SUCCESS] Ant installed

[INFO] Intranet Check
[SUCCESS] Connected

Final Status: ❌ FAILED
```

---

## 15. Key Design Principles

- Deterministic output
- Idempotent config commands
- Strict version enforcement
- Minimal external dependencies
- Developer-first UX

