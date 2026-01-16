import {themes as prismThemes} from 'prism-react-renderer';
import type {Config} from '@docusaurus/types';
import type * as Preset from '@docusaurus/preset-classic';

// Environment variables for configurable repository URLs
// - In GitHub Actions: automatically set from repository context
// - In local dev: uses defaults (terchris/devcontainer-toolbox)
// - For forks: set GITHUB_ORG and GITHUB_REPO env vars or let CI auto-detect
const GITHUB_ORG = process.env.GITHUB_ORG || 'terchris';
const GITHUB_REPO = process.env.GITHUB_REPO || 'devcontainer-toolbox';

const config: Config = {
  title: 'DevContainer Toolbox',
  tagline: 'One command. Full dev environment. Any project.',
  favicon: 'img/favicon.ico',

  future: {
    v4: true,
  },

  // GitHub Pages URL (configured via env vars for fork compatibility)
  url: `https://${GITHUB_ORG}.github.io`,
  baseUrl: `/${GITHUB_REPO}/`,

  // GitHub pages deployment config
  organizationName: GITHUB_ORG,
  projectName: GITHUB_REPO,

  onBrokenLinks: 'throw',

  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },

  presets: [
    [
      'classic',
      {
        docs: {
          sidebarPath: './sidebars.ts',
          editUrl: `https://github.com/${GITHUB_ORG}/${GITHUB_REPO}/tree/main/website/`,
        },
        blog: false, // Disable blog for now
        theme: {
          customCss: './src/css/custom.css',
        },
      } satisfies Preset.Options,
    ],
  ],

  themes: [
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

  themeConfig: {
    image: 'img/docusaurus-social-card.jpg',
    colorMode: {
      defaultMode: 'light',
      respectPrefersColorScheme: true,
    },
    navbar: {
      title: 'DevContainer Toolbox',
      logo: {
        alt: 'DevContainer Toolbox Logo',
        src: 'img/logo.svg',
      },
      items: [
        {
          type: 'docSidebar',
          sidebarId: 'docsSidebar',
          position: 'left',
          label: 'Docs',
        },
        {
          href: `https://github.com/${GITHUB_ORG}/${GITHUB_REPO}`,
          label: 'GitHub',
          position: 'right',
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
              to: '/docs/getting-started',
            },
            {
              label: 'Available Tools',
              to: '/docs/tools',
            },
          ],
        },
        {
          title: 'Community',
          items: [
            {
              label: 'GitHub Discussions',
              href: `https://github.com/${GITHUB_ORG}/${GITHUB_REPO}/discussions`,
            },
            {
              label: 'Issues',
              href: `https://github.com/${GITHUB_ORG}/${GITHUB_REPO}/issues`,
            },
          ],
        },
        {
          title: 'More',
          items: [
            {
              label: 'GitHub',
              href: `https://github.com/${GITHUB_ORG}/${GITHUB_REPO}`,
            },
          ],
        },
      ],
      copyright: `Copyright © ${new Date().getFullYear()} DevContainer Toolbox. Built with Docusaurus.`,
    },
    prism: {
      theme: prismThemes.github,
      darkTheme: prismThemes.dracula,
      additionalLanguages: ['bash', 'powershell', 'json'],
    },
  } satisfies Preset.ThemeConfig,
};

export default config;
