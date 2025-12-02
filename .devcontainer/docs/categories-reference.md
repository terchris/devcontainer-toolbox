# Script Categories Reference

This document lists all valid script categories for the devcontainer toolbox.

## Purpose

Categories organize installation scripts in the menu system and documentation. When creating new install scripts, you must use one of these predefined categories in the `SCRIPT_CATEGORY` field.

## Valid Categories

### LANGUAGE_DEV - Development Tools

**Display Name:** Development Tools

**Description:** Programming language development environments and tools (Python, TypeScript, Go, Rust, C#, Java, PHP)

**Examples:**
- install-dev-python.sh
- install-dev-typescript.sh
- install-dev-golang.sh
- install-dev-rust.sh
- install-dev-csharp.sh

---

### AI_TOOLS - AI & Machine Learning Tools

**Display Name:** AI & Machine Learning Tools

**Description:** AI and machine learning development tools (Claude Code, etc.)

**Examples:**
- install-dev-ai-claudecode.sh

---

### CLOUD_TOOLS - Cloud & Infrastructure Tools

**Display Name:** Cloud & Infrastructure Tools

**Description:** Cloud platform tools and SDKs (Azure, AWS, GCP)

**Examples:**
- install-tool-azure.sh

---

### DATA_ANALYTICS - Data & Analytics Tools

**Display Name:** Data & Analytics Tools

**Description:** Data analysis, visualization, and data engineering tools (Jupyter, pandas, DBT)

**Examples:**
- install-tool-dataanalytics.sh

---

### INFRA_CONFIG - Infrastructure & Configuration

**Display Name:** Infrastructure & Configuration

**Description:** Infrastructure as Code, configuration management, and DevOps tools (Ansible, Kubernetes, Terraform)

**Examples:**
- install-dev-powershell.sh
- install-srv-nginx.sh
- install-srv-otel-monitoring.sh
- install-tool-iac.sh
- install-tool-kubernetes.sh

---

## Using Categories in Your Script

When creating a new install script, set the `SCRIPT_CATEGORY` variable in the configuration section:

```bash
#------------------------------------------------------------------------------
# CONFIGURATION - Modify this section for each new script
#------------------------------------------------------------------------------

# Script metadata
SCRIPT_NAME="Your Tool Name"
SCRIPT_ID="your-tool"
SCRIPT_DESCRIPTION="Brief description of what this installs"
SCRIPT_CATEGORY="LANGUAGE_DEV"  # Use one of the valid categories above
CHECK_INSTALLED_COMMAND="command -v your-tool >/dev/null 2>&1"
```

## Category Validation

The system will validate that you're using a valid category. If you need a new category:

1. Edit `.devcontainer/additions/lib/categories.sh`
2. Add a new line to the `CATEGORY_TABLE` with format:
   ```
   SORT_ORDER|CATEGORY_ID|DISPLAY_NAME|SHORT_DESCRIPTION|LONG_DESCRIPTION
   ```
   Example:
   ```
   6|NEW_CATEGORY|New Category Name|Short desc|Longer detailed description
   ```
3. Optionally add a constant (e.g., `readonly CATEGORY_NEW_CATEGORY="NEW_CATEGORY"`)
4. Update this reference document

That's it! The table structure makes adding categories simple - just one line.

## Viewing Categories Programmatically

You can view all categories from the command line:

```bash
cd .devcontainer/additions
source lib/categories.sh

# Show detailed information
show_all_categories

# Show as a table
show_categories_table

# List just IDs and names
list_categories_simple

# Get machine-readable format
list_categories
```

## Implementation Details

### Table Structure

Categories are defined in a simple table format in `.devcontainer/additions/lib/categories.sh`:

```bash
readonly CATEGORY_TABLE="
SORT_ORDER|CATEGORY_ID|DISPLAY_NAME|SHORT_DESCRIPTION|LONG_DESCRIPTION
1|LANGUAGE_DEV|Development Tools|Development tools (Python, TypeScript, Go, etc.)|Programming language development environments and tools...
2|AI_TOOLS|AI & Machine Learning Tools|AI and ML tools (Claude Code, etc.)|AI and machine learning development tools...
"
```

**Format:** Pipe-delimited with 5 fields:
1. **SORT_ORDER** - Controls display order (1, 2, 3, ...)
2. **CATEGORY_ID** - Unique identifier (UPPERCASE_UNDERSCORE)
3. **DISPLAY_NAME** - Human-readable name
4. **SHORT_DESCRIPTION** - Brief description for help text (< 60 chars)
5. **LONG_DESCRIPTION** - Detailed description for documentation

### Benefits of Table Structure

- **Easy to maintain** - One line per category
- **Simple to add** - Just append a new line
- **Self-documenting** - Table format is clear and readable
- **Sortable** - SORT_ORDER field controls display order
- **No code duplication** - All helper functions parse the same table

### Used By

- `.devcontainer/manage/generate-manual.sh` - Documentation generation
- `.devcontainer/additions/addition-templates/_template-install-script.sh` - Template documentation
- Menu system (future implementation)
- Any script that needs to display or validate categories

This ensures consistency across all tooling and documentation.
