#!/bin/bash
# file: .devcontainer/additions/install-fwk-docusaurus.sh
#
# Installs a complete Docusaurus documentation site in website/ with
# GitHub Pages CI/CD deployment workflow.
# For usage information, run: ./install-fwk-docusaurus.sh --help
#
#------------------------------------------------------------------------------
# CONFIGURATION
#------------------------------------------------------------------------------

# --- Core Metadata (required for dev-setup.sh) ---
SCRIPT_ID="fwk-docusaurus"
SCRIPT_VER="0.1.0"
SCRIPT_NAME="Docusaurus"
SCRIPT_DESCRIPTION="Installs a Docusaurus documentation site with GitHub Pages deployment."
SCRIPT_CATEGORY="FRAMEWORKS"
SCRIPT_CHECK_COMMAND="[ -d /workspace/website ]"

# --- Extended Metadata (for website documentation) ---
SCRIPT_TAGS="docusaurus static-site-generator ssg framework web documentation react"
SCRIPT_ABSTRACT="Docusaurus documentation site with TypeScript, Mermaid, local search, and GitHub Pages CI/CD."
SCRIPT_LOGO="fwk-docusaurus-logo.webp"
SCRIPT_WEBSITE="https://docusaurus.io"
SCRIPT_SUMMARY="Installs a complete Docusaurus 3.x documentation site in website/ with TypeScript configuration, Mermaid diagram support, local search, image zoom, auto-generated sidebars, and a GitHub Actions workflow for deploying to GitHub Pages."
SCRIPT_RELATED="fwk-hugo"

# Commands for dev-setup.sh menu integration
SCRIPT_COMMANDS=(
    "Action||Install Docusaurus site and CI/CD workflow||false|"
    "Action|--uninstall|Uninstall Docusaurus site and workflow||false|"
    "Info|--help|Show help and usage information||false|"
)

# System packages (none needed — Node.js is pre-installed)
PACKAGES_SYSTEM=()

# VS Code extensions
EXTENSIONS=(
    "MDX (unifiedjs.vscode-mdx) - MDX language support with syntax highlighting and IntelliSense"
    "Front Matter CMS (eliostruyf.vscode-front-matter) - Content management for static site generators"
)

#------------------------------------------------------------------------------

# Source auto-enable library
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/lib/tool-auto-enable.sh"

# Source logging library
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/lib/logging.sh"

# Target directories
WEBSITE_DIR="/workspace/website"
WORKFLOW_DIR="/workspace/.github/workflows"
WORKFLOW_FILE="${WORKFLOW_DIR}/deploy-docs.yml"

#------------------------------------------------------------------------------
# Generated File Content
#------------------------------------------------------------------------------

generate_package_json() {
    cat << 'PACKAGE_EOF'
{
  "name": "website",
  "version": "0.0.0",
  "private": true,
  "scripts": {
    "docusaurus": "docusaurus",
    "start": "docusaurus start",
    "build": "docusaurus build",
    "swizzle": "docusaurus swizzle",
    "deploy": "docusaurus deploy",
    "clear": "docusaurus clear",
    "serve": "docusaurus serve",
    "write-translations": "docusaurus write-translations",
    "write-heading-ids": "docusaurus write-heading-ids",
    "typecheck": "tsc"
  },
  "dependencies": {
    "@docusaurus/core": "3.9.2",
    "@docusaurus/preset-classic": "3.9.2",
    "@docusaurus/theme-mermaid": "^3.9.2",
    "@easyops-cn/docusaurus-search-local": "^0.52.2",
    "@mdx-js/react": "^3.0.0",
    "clsx": "^2.0.0",
    "docusaurus-plugin-image-zoom": "^3.0.1",
    "prism-react-renderer": "^2.3.0",
    "react": "^19.0.0",
    "react-dom": "^19.0.0"
  },
  "devDependencies": {
    "@docusaurus/module-type-aliases": "3.9.2",
    "@docusaurus/tsconfig": "3.9.2",
    "@docusaurus/types": "3.9.2",
    "typescript": "~5.6.2"
  },
  "browserslist": {
    "production": [
      ">0.5%",
      "not dead",
      "not op_mini all"
    ],
    "development": [
      "last 3 chrome version",
      "last 3 firefox version",
      "last 5 safari version"
    ]
  },
  "engines": {
    "node": ">=20.0"
  }
}
PACKAGE_EOF
}

generate_docusaurus_config() {
    cat << 'CONFIG_EOF'
import {themes as prismThemes} from 'prism-react-renderer';
import type {Config} from '@docusaurus/types';
import type * as Preset from '@docusaurus/preset-classic';

const config: Config = {
  title: 'My Project',
  tagline: 'Documentation for My Project',
  favicon: 'img/favicon.ico',

  future: {
    v4: true,
  },

  url: 'https://example.com',
  baseUrl: '/',

  onBrokenLinks: 'throw',

  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },

  markdown: {
    mermaid: true,
  },

  presets: [
    [
      'classic',
      {
        docs: {
          sidebarPath: './sidebars.ts',
        },
        blog: {
          showReadingTime: true,
          blogTitle: 'Blog',
          blogDescription: 'Project blog and updates',
          postsPerPage: 10,
          blogSidebarTitle: 'Recent posts',
          blogSidebarCount: 5,
        },
        theme: {
          customCss: './src/css/custom.css',
        },
      } satisfies Preset.Options,
    ],
  ],

  themes: [
    '@docusaurus/theme-mermaid',
    [
      '@easyops-cn/docusaurus-search-local',
      {
        hashed: true,
        language: ['en'],
        highlightSearchTermsOnTargetPage: true,
        explicitSearchResultPath: true,
        docsRouteBasePath: '/docs',
      },
    ],
  ],

  plugins: [
    'docusaurus-plugin-image-zoom',
  ],

  themeConfig: {
    image: 'img/social-card.jpg',
    colorMode: {
      defaultMode: 'light',
      respectPrefersColorScheme: true,
    },
    navbar: {
      title: 'My Project',
      items: [
        {
          type: 'docSidebar',
          sidebarId: 'docsSidebar',
          position: 'left',
          label: 'Docs',
        },
        {
          to: '/blog',
          label: 'Blog',
          position: 'left',
        },
      ],
    },
    footer: {
      style: 'dark',
      links: [
        {
          title: 'Documentation',
          items: [
            {
              label: 'Getting Started',
              to: '/docs/',
            },
          ],
        },
        {
          title: 'More',
          items: [
            {
              label: 'Blog',
              to: '/blog',
            },
          ],
        },
      ],
      copyright: `Copyright © ${new Date().getFullYear()} My Project.`,
    },
    prism: {
      theme: prismThemes.github,
      darkTheme: prismThemes.dracula,
      additionalLanguages: ['bash', 'json'],
    },
    zoom: {
      selector: '.markdown img',
      background: {
        light: 'rgb(255, 255, 255)',
        dark: 'rgb(50, 50, 50)',
      },
    },
  } satisfies Preset.ThemeConfig,
};

export default config;
CONFIG_EOF
}

generate_sidebars() {
    cat << 'SIDEBARS_EOF'
import type {SidebarsConfig} from '@docusaurus/plugin-content-docs';

const sidebars: SidebarsConfig = {
  docsSidebar: [{type: 'autogenerated', dirName: '.'}],
};

export default sidebars;
SIDEBARS_EOF
}

generate_tsconfig() {
    cat << 'TSCONFIG_EOF'
{
  "extends": "@docusaurus/tsconfig",
  "compilerOptions": {
    "baseUrl": "."
  },
  "exclude": [".docusaurus", "build"]
}
TSCONFIG_EOF
}

generate_custom_css() {
    cat << 'CSS_EOF'
/**
 * Any CSS included here will be global. The classic template
 * bundles Infima by default. Infima is a CSS framework designed to
 * work well for content-centric websites.
 */

:root {
  --ifm-color-primary: #2e8555;
  --ifm-color-primary-dark: #29784c;
  --ifm-color-primary-darker: #277148;
  --ifm-color-primary-darkest: #205d3b;
  --ifm-color-primary-light: #33925d;
  --ifm-color-primary-lighter: #359962;
  --ifm-color-primary-lightest: #3cad6e;
  --ifm-code-font-size: 95%;
  --docusaurus-highlighted-code-line-bg: rgba(0, 0, 0, 0.1);
}

[data-theme='dark'] {
  --ifm-color-primary: #25c2a0;
  --ifm-color-primary-dark: #21af90;
  --ifm-color-primary-darker: #1fa588;
  --ifm-color-primary-darkest: #1a8870;
  --ifm-color-primary-light: #29d5b0;
  --ifm-color-primary-lighter: #32d8b4;
  --ifm-color-primary-lightest: #4fddbf;
  --docusaurus-highlighted-code-line-bg: rgba(0, 0, 0, 0.3);
}
CSS_EOF
}

generate_index_page() {
    cat << 'INDEX_EOF'
import type {ReactNode} from 'react';
import Link from '@docusaurus/Link';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import Layout from '@theme/Layout';
import Heading from '@theme/Heading';

function HomepageHeader() {
  const {siteConfig} = useDocusaurusContext();
  return (
    <header style={{padding: '4rem 0', textAlign: 'center'}}>
      <div className="container">
        <Heading as="h1" className="hero__title">
          {siteConfig.title}
        </Heading>
        <p className="hero__subtitle">{siteConfig.tagline}</p>
        <div>
          <Link
            className="button button--primary button--lg"
            to="/docs/">
            Get Started
          </Link>
        </div>
      </div>
    </header>
  );
}

export default function Home(): ReactNode {
  const {siteConfig} = useDocusaurusContext();
  return (
    <Layout
      title="Home"
      description={siteConfig.tagline}>
      <HomepageHeader />
      <main>
        <div className="container" style={{padding: '2rem 0'}}>
          <div className="row">
            <div className="col col--4">
              <h3>Easy to Use</h3>
              <p>Get your documentation site up and running quickly.</p>
            </div>
            <div className="col col--4">
              <h3>Powered by React</h3>
              <p>Extend and customize with React components.</p>
            </div>
            <div className="col col--4">
              <h3>Built-in Search</h3>
              <p>Local search included out of the box.</p>
            </div>
          </div>
        </div>
      </main>
    </Layout>
  );
}
INDEX_EOF
}

generate_docs_index() {
    cat << 'DOCS_EOF'
---
slug: /
sidebar_position: 1
---

# Welcome

Welcome to the documentation.

## Getting Started

Start by editing this file at `docs/index.md`.

## Features

This site includes:

- **Mermaid diagrams** — use fenced code blocks with `mermaid` language
- **Local search** — full-text search built in
- **Image zoom** — click images to zoom
- **Dark mode** — automatic based on system preference

## Example Mermaid Diagram

```mermaid
graph LR
    A[Write Docs] --> B[Build Site]
    B --> C[Deploy]
```
DOCS_EOF
}

generate_authors_yml() {
    cat << 'AUTHORS_EOF'
default:
  name: Author Name
  title: Project Contributor
  url: https://github.com
AUTHORS_EOF
}

generate_first_blog_post() {
    cat << 'BLOG_EOF'
---
slug: welcome
title: Welcome
authors: [default]
tags: [welcome]
---

Welcome to the blog. This is the first post.

<!-- truncate -->

You can add more blog posts in the `blog/` directory.
BLOG_EOF
}

generate_deploy_workflow() {
    cat << 'WORKFLOW_EOF'
name: Deploy Documentation

on:
  push:
    branches:
      - main
    paths:
      - 'website/**'
      - '.github/workflows/deploy-docs.yml'
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: "pages"
  cancel-in-progress: true

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
          cache-dependency-path: website/package-lock.json

      - name: Install dependencies
        working-directory: website
        run: npm ci

      - name: Build website
        working-directory: website
        run: npm run build

      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: website/build

  deploy:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    needs: build
    steps:
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
WORKFLOW_EOF
}

#------------------------------------------------------------------------------
# Pre-installation/Uninstallation Setup
#------------------------------------------------------------------------------

pre_installation_setup() {
    if [ "${UNINSTALL_MODE}" -eq 1 ]; then
        echo "🔧 Preparing for Docusaurus uninstallation..."
    else
        echo "🔧 Performing pre-installation setup for Docusaurus..."

        # Check Node.js is available
        if ! command -v node >/dev/null 2>&1; then
            log_error "Node.js is not installed. It is required for Docusaurus."
            exit 1
        fi

        if ! command -v npm >/dev/null 2>&1; then
            log_error "npm is not installed. It is required for Docusaurus."
            exit 1
        fi

        # Check website/ doesn't already exist
        if [ -d "$WEBSITE_DIR" ] && [ "${FORCE_MODE}" -eq 0 ]; then
            log_info "Docusaurus site already exists at $WEBSITE_DIR"
            log_info "Use --force to reinstall."
            exit 0
        fi
    fi
}

#------------------------------------------------------------------------------
# Post-installation/Uninstallation Messages
#------------------------------------------------------------------------------

post_installation_message() {
    echo
    echo "🎉 Installation complete!"
    echo
    echo "Quick start:"
    echo "  cd /workspace/website"
    echo "  npm run start -- --host 0.0.0.0    # Start dev server"
    echo "  npm run build                       # Build for production"
    echo
    echo "Edit your site:"
    echo "  website/docusaurus.config.ts        # Site configuration"
    echo "  website/docs/                       # Documentation pages"
    echo "  website/blog/                       # Blog posts"
    echo "  website/src/pages/index.tsx         # Homepage"
    echo "  website/src/css/custom.css          # Custom styles"
    echo
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "⚠️  REQUIRED: Enable GitHub Pages"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo
    echo "  1. Go to your repo on GitHub"
    echo "  2. Settings → Pages"
    echo "  3. Source: select 'GitHub Actions'"
    echo "  4. Push to main — the workflow will deploy automatically"
    echo
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📌 OPTIONAL: Custom domain"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo
    echo "  1. Create website/static/CNAME with your domain:"
    echo "     echo 'docs.example.com' > website/static/CNAME"
    echo
    echo "  2. Update url in website/docusaurus.config.ts:"
    echo "     url: 'https://docs.example.com',"
    echo
    echo "  3. Configure DNS — add a CNAME record:"
    echo "     docs.example.com → <username>.github.io"
    echo
    echo "  4. In GitHub repo Settings → Pages → Custom domain:"
    echo "     enter your domain and enable 'Enforce HTTPS'"
    echo
    echo "Docs: https://docusaurus.io/docs"
    echo "GitHub Pages: https://docs.github.com/en/pages"
    echo
}

post_uninstallation_message() {
    echo
    echo "🏁 Uninstallation complete!"
    if [ -d "$WEBSITE_DIR" ]; then
        echo "   ⚠️  website/ directory still exists"
    else
        echo "   ✅ website/ removed"
    fi
    if [ -f "$WORKFLOW_FILE" ]; then
        echo "   ⚠️  deploy-docs.yml still exists"
    else
        echo "   ✅ deploy-docs.yml removed"
    fi
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

source "${SCRIPT_DIR}/lib/core-install-system.sh"
source "${SCRIPT_DIR}/lib/core-install-extensions.sh"

#------------------------------------------------------------------------------
# HELPER FUNCTIONS
#------------------------------------------------------------------------------

install_docusaurus_site() {
    # Create directory structure
    log_info "Creating directory structure..."
    mkdir -p "$WEBSITE_DIR"/{docs,blog,src/css,src/pages,static/img}

    # Generate config files
    log_info "Generating configuration files..."
    generate_package_json > "$WEBSITE_DIR/package.json"
    generate_docusaurus_config > "$WEBSITE_DIR/docusaurus.config.ts"
    generate_sidebars > "$WEBSITE_DIR/sidebars.ts"
    generate_tsconfig > "$WEBSITE_DIR/tsconfig.json"

    # Generate starter content
    log_info "Generating starter content..."
    generate_custom_css > "$WEBSITE_DIR/src/css/custom.css"
    generate_index_page > "$WEBSITE_DIR/src/pages/index.tsx"
    generate_docs_index > "$WEBSITE_DIR/docs/index.md"
    generate_authors_yml > "$WEBSITE_DIR/blog/authors.yml"
    generate_first_blog_post > "$WEBSITE_DIR/blog/welcome.md"

    # Generate CI/CD workflow
    log_info "Generating GitHub Actions workflow..."
    mkdir -p "$WORKFLOW_DIR"
    generate_deploy_workflow > "$WORKFLOW_FILE"

    # Run npm install
    log_info "Running npm install (this may take a minute)..."
    echo ""
    if (cd "$WEBSITE_DIR" && npm install); then
        echo ""
        log_success "Docusaurus site created successfully!"
    else
        echo ""
        log_error "npm install failed. Files created but dependencies not installed."
        log_info "Try running: cd $WEBSITE_DIR && npm install"
        return 1
    fi
}

uninstall_docusaurus_site() {
    # Remove website directory
    if [ -d "$WEBSITE_DIR" ]; then
        log_info "Removing $WEBSITE_DIR ..."
        rm -rf "$WEBSITE_DIR"
        log_success "website/ removed"
    else
        log_info "No website/ directory found"
    fi

    # Remove workflow file
    if [ -f "$WORKFLOW_FILE" ]; then
        log_info "Removing $WORKFLOW_FILE ..."
        rm -f "$WORKFLOW_FILE"
        log_success "deploy-docs.yml removed"
    else
        log_info "No deploy-docs.yml found"
    fi
}

# Function to process installations
process_installations() {
    if [ "${UNINSTALL_MODE}" -eq 1 ]; then
        uninstall_docusaurus_site

        # Uninstall extensions
        if [ ${#EXTENSIONS[@]} -gt 0 ]; then
            process_extensions "EXTENSIONS"
        fi
    else
        install_docusaurus_site

        # Install extensions
        process_standard_installations
    fi
}

#------------------------------------------------------------------------------
# MAIN EXECUTION
#------------------------------------------------------------------------------

if [ "${UNINSTALL_MODE}" -eq 1 ]; then
    show_install_header "uninstall"
    pre_installation_setup
    process_installations
    post_uninstallation_message

    # Remove from auto-enable config
    auto_disable_tool
else
    show_install_header
    pre_installation_setup
    process_installations
    post_installation_message

    # Auto-enable for container rebuild
    auto_enable_tool
fi

echo "✅ Script execution finished."
exit 0
