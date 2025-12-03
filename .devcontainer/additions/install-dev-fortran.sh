#!/bin/bash
# file: .devcontainer/additions/install-dev-fortran.sh
#
# For usage information, run: ./install-dev-fortran.sh --help
#
#------------------------------------------------------------------------------
# CONFIGURATION - Modify this section for each new script
#------------------------------------------------------------------------------

# Script metadata - must be at the very top of the configuration section
SCRIPT_ID="dev-fortran"
SCRIPT_NAME="Fortran Development Tools"
SCRIPT_DESCRIPTION="Installs GNU Fortran compiler (gfortran), build tools, and VS Code extensions for Fortran development"
SCRIPT_CATEGORY="LANGUAGE_DEV"
CHECK_INSTALLED_COMMAND="command -v gfortran >/dev/null 2>&1"

# Custom usage text for --help
SCRIPT_USAGE="  $(basename "$0")              # Install
  $(basename "$0") --help       # Show this help
  $(basename "$0") --uninstall  # Uninstall"

# System packages
PACKAGES_SYSTEM=(
    "gfortran"
    "build-essential"
    "cmake"
    "make"
    "liblapack-dev"
    "libblas-dev"
)

# VS Code extensions
EXTENSIONS=(
    "Modern Fortran (fortran-lang.linter-gfortran) - Fortran language support with linting and IntelliSense"
    "Fortran IntelliSense (hansec.fortran-ls) - Language server for Fortran"
    "Fortran Breakpoint Support (ekibun.fortranbreaker) - Debugging support for Fortran"
)

#------------------------------------------------------------------------------

# Source auto-enable library
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/lib/tool-auto-enable.sh"

# Source logging library
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/lib/logging.sh"

#------------------------------------------------------------------------------

# Before running installation, we need to add any required repositories or setup
pre_installation_setup() {
    if [ "${UNINSTALL_MODE}" -eq 1 ]; then
        echo "🔧 Preparing for uninstallation..."
    else
        echo "🔧 Performing pre-installation setup..."

        # Check if gfortran is already installed
        if command -v gfortran >/dev/null 2>&1; then
            echo "✅ gfortran is already installed (version: $(gfortran --version | head -1))"
        fi

        echo "✅ Pre-installation setup complete"
    fi
}

# Post-installation notes
post_installation_message() {
    local gfortran_version
    gfortran_version=$(gfortran --version 2>/dev/null | head -1 || echo "not found")

    echo
    echo "🎉 Installation complete!"
    echo "   GNU Fortran: $gfortran_version"
    echo
    echo "Quick start:"
    echo "  - Compile:     gfortran -o myprogram myprogram.f90"
    echo "  - With debug:  gfortran -g -o myprogram myprogram.f90"
    echo "  - With OpenMP: gfortran -fopenmp -o myprogram myprogram.f90"
    echo
    echo "Example hello.f90:"
    echo "  program hello"
    echo "      print *, 'Hello, Fortran!'"
    echo "  end program hello"
    echo
    echo "Docs: https://gcc.gnu.org/wiki/GFortran"
    echo
}

# Post-uninstallation notes
post_uninstallation_message() {
    echo
    echo "🏁 Uninstallation complete!"
    echo "   ✅ Fortran development tools removed"
    echo
    echo "Note: Some shared libraries (lapack, blas) may remain if used by other packages"
    echo
}

#------------------------------------------------------------------------------
# ARGUMENT PARSING
#------------------------------------------------------------------------------

# Initialize mode flags
DEBUG_MODE=0
UNINSTALL_MODE=0
FORCE_MODE=0

# Source common installation patterns library (needed for --help)
source "${SCRIPT_DIR}/lib/install-common.sh"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --help)
            show_script_help
            exit 0
            ;;
        --debug)
            DEBUG_MODE=1
            shift
            ;;
        --uninstall)
            UNINSTALL_MODE=1
            shift
            ;;
        --force)
            FORCE_MODE=1
            shift
            ;;
        *)
            echo "ERROR: Unknown option: $1" >&2
            echo "Usage: $0 [--help] [--debug] [--uninstall] [--force]" >&2
            echo "Description: $SCRIPT_DESCRIPTION"
            exit 1
            ;;
    esac
done

# Export mode flags
export DEBUG_MODE
export UNINSTALL_MODE
export FORCE_MODE

#------------------------------------------------------------------------------
# SOURCE CORE SCRIPTS
#------------------------------------------------------------------------------

# Source core installation scripts
source "${SCRIPT_DIR}/lib/core-install-system.sh"
source "${SCRIPT_DIR}/lib/core-install-extensions.sh"

#------------------------------------------------------------------------------
# HELPER FUNCTIONS
#------------------------------------------------------------------------------

# Function to process installations
process_installations() {
    if [ "${UNINSTALL_MODE}" -eq 1 ]; then
        # During uninstall: reverse order to uninstall dependents before dependencies
        # 1. Extensions (no dependencies)
        if [ ${#EXTENSIONS[@]} -gt 0 ]; then
            process_extensions "EXTENSIONS"
        fi
        # 2. System packages (base dependencies, removed last)
        if [ ${#PACKAGES_SYSTEM[@]} -gt 0 ]; then
            process_system_packages "PACKAGES_SYSTEM"
        fi
    else
        # During install: use standard processing
        process_standard_installations
    fi
}

#------------------------------------------------------------------------------
# MAIN EXECUTION
#------------------------------------------------------------------------------

if [ "${UNINSTALL_MODE}" -eq 1 ]; then
    echo "🔄 Starting uninstallation process for: $SCRIPT_NAME"
    echo "Purpose: $SCRIPT_DESCRIPTION"
    pre_installation_setup
    process_installations
    post_uninstallation_message

    # Remove from auto-enable config
    auto_disable_tool
else
    echo "🔄 Starting installation process for: $SCRIPT_NAME"
    echo "Purpose: $SCRIPT_DESCRIPTION"
    pre_installation_setup
    process_installations
    post_installation_message

    # Auto-enable for container rebuild
    auto_enable_tool
fi

echo "✅ Script execution finished."
exit 0
