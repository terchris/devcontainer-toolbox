#!/bin/bash
# file: .devcontainer/additions/cmd-fwk-docusaurus.sh
#
# Scaffolds a ready-to-go Docusaurus documentation site in website/.
# For usage information, run: ./cmd-fwk-docusaurus.sh --help
#
#------------------------------------------------------------------------------
# CONFIGURATION
#------------------------------------------------------------------------------

# --- Core Metadata (required for dev-setup.sh) ---
SCRIPT_ID="cmd-fwk-docusaurus"
SCRIPT_VER="0.0.1"
SCRIPT_NAME="Docusaurus Scaffold"
SCRIPT_DESCRIPTION="Scaffold a Docusaurus documentation site in website/"
SCRIPT_CATEGORY="FRAMEWORKS"
SCRIPT_CHECK_COMMAND="command -v npx >/dev/null 2>&1"
SCRIPT_PREREQUISITES=""

# --- Extended Metadata (for website documentation) ---
SCRIPT_TAGS="docusaurus static-site-generator ssg framework web documentation react"
SCRIPT_ABSTRACT="Scaffold a ready-to-go Docusaurus documentation site with TypeScript, Mermaid, and local search."
SCRIPT_LOGO="cmd-fwk-docusaurus-logo.webp"
SCRIPT_WEBSITE="https://docusaurus.io"
SCRIPT_SUMMARY="Scaffolds a complete Docusaurus 3.x documentation site in website/ with TypeScript configuration, Mermaid diagram support, local search, image zoom, and auto-generated sidebars. Includes starter docs, blog, and homepage."
SCRIPT_RELATED="fwk-hugo"

#------------------------------------------------------------------------------
# SCRIPT_COMMANDS DEFINITIONS
#------------------------------------------------------------------------------

SCRIPT_COMMANDS=(
    "Action|--create|Create a new Docusaurus site in website/|cmd_create|false|"
    "Info|--help|Show help and usage information|show_help|false|"
)

# VS Code extensions
EXTENSIONS=(
    "MDX (unifiedjs.vscode-mdx) - MDX language support with syntax highlighting and IntelliSense"
    "Front Matter CMS (eliostruyf.vscode-front-matter) - Content management for static site generators"
)

#------------------------------------------------------------------------------

set -euo pipefail

# Source libraries
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/lib/logging.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/lib/core-install-extensions.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/lib/display-utils.sh"

# Target directory (always website/ in the repo root)
WEBSITE_DIR="${WEBSITE_DIR:-/workspace/website}"

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

#------------------------------------------------------------------------------
# Command Functions
#------------------------------------------------------------------------------

cmd_create() {
    draw_heavy_line
    echo "📦 Docusaurus Site Scaffold"
    draw_heavy_line
    echo ""

    # Check Node.js is available
    if ! command -v node >/dev/null 2>&1; then
        log_error "Node.js is not installed. It is required for Docusaurus."
        return 1
    fi

    if ! command -v npm >/dev/null 2>&1; then
        log_error "npm is not installed. It is required for Docusaurus."
        return 1
    fi

    # Check website/ doesn't already exist
    if [ -d "$WEBSITE_DIR" ]; then
        log_error "Directory already exists: $WEBSITE_DIR"
        log_info "Remove it first if you want to start fresh."
        return 1
    fi

    log_info "Creating Docusaurus site in $WEBSITE_DIR ..."
    echo ""

    # Create directory structure
    log_info "Creating directory structure..."
    mkdir -p "$WEBSITE_DIR"/{docs,blog,src/css,src/pages,static/img}

    # Generate files
    log_info "Generating configuration files..."
    generate_package_json > "$WEBSITE_DIR/package.json"
    generate_docusaurus_config > "$WEBSITE_DIR/docusaurus.config.ts"
    generate_sidebars > "$WEBSITE_DIR/sidebars.ts"
    generate_tsconfig > "$WEBSITE_DIR/tsconfig.json"

    log_info "Generating starter content..."
    generate_custom_css > "$WEBSITE_DIR/src/css/custom.css"
    generate_index_page > "$WEBSITE_DIR/src/pages/index.tsx"
    generate_docs_index > "$WEBSITE_DIR/docs/index.md"
    generate_authors_yml > "$WEBSITE_DIR/blog/authors.yml"
    generate_first_blog_post > "$WEBSITE_DIR/blog/welcome.md"

    # Run npm install
    log_info "Running npm install (this may take a minute)..."
    echo ""
    if (cd "$WEBSITE_DIR" && npm install); then
        echo ""
        log_success "Docusaurus site created successfully!"

        # Install VS Code extensions
        log_info "Installing VS Code extensions..."
        process_extensions "EXTENSIONS"
    else
        echo ""
        log_error "npm install failed. The files have been created but dependencies are not installed."
        log_info "Try running: cd $WEBSITE_DIR && npm install"
        return 1
    fi

    echo ""
    draw_heavy_line
    echo ""
    echo "Quick start:"
    echo "  cd $WEBSITE_DIR"
    echo "  npm run start              # Start dev server"
    echo "  npm run build              # Build for production"
    echo ""
    echo "Edit your site:"
    echo "  docusaurus.config.ts       # Site configuration"
    echo "  docs/                      # Documentation pages"
    echo "  blog/                      # Blog posts"
    echo "  src/pages/index.tsx        # Homepage"
    echo "  src/css/custom.css         # Custom styles"
    echo ""
    echo "Docs: https://docusaurus.io/docs"
    echo ""
    draw_heavy_line
}

#------------------------------------------------------------------------------
# Help and Argument Parsing
#------------------------------------------------------------------------------

show_help() {
    # Source framework if not already loaded
    if ! declare -f cmd_framework_generate_help >/dev/null 2>&1; then
        # shellcheck source=/dev/null
        source "${SCRIPT_DIR}/lib/cmd-framework.sh"
    fi

    cmd_framework_generate_help SCRIPT_COMMANDS "cmd-fwk-docusaurus.sh" "$SCRIPT_VER"

    echo ""
    echo "VS Code Extensions (installed automatically):"
    for ext in "${EXTENSIONS[@]}"; do
        echo "  - $ext"
    done

    echo ""
    echo "Examples:"
    echo "  cmd-fwk-docusaurus.sh --create    # Create Docusaurus site in website/"
    echo ""
}

parse_args() {
    # Source framework if not already loaded
    if ! declare -f cmd_framework_parse_args >/dev/null 2>&1; then
        # shellcheck source=/dev/null
        source "${SCRIPT_DIR}/lib/cmd-framework.sh"
    fi

    cmd_framework_parse_args SCRIPT_COMMANDS "cmd-fwk-docusaurus.sh" "$@"
}

#------------------------------------------------------------------------------
# Main
#------------------------------------------------------------------------------

main() {
    if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
        show_help
        exit 0
    fi

    if [ $# -eq 0 ]; then
        show_help
        exit 0
    fi

    parse_args "$@"
}

main "$@"
