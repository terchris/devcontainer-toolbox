#!/bin/bash
# dev-help.sh - Show available dev-* commands

cat << 'EOF'
Available dev-* commands:

  dev-setup      Configure which tools to enable
  dev-services   Manage development services
  dev-template   Create files from templates
  dev-update     Update devcontainer-toolbox
  dev-check      Validate configuration files
  dev-env        Show environment information
  dev-clean      Clean up devcontainer resources
  dev-help       Show this help message

Run any command with --help for more details.
EOF
