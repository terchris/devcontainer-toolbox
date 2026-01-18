import {themes as prismThemes} from 'prism-react-renderer';
import type {Config} from '@docusaurus/types';
import type * as Preset from '@docusaurus/preset-classic';
import fs from 'fs';

// Read version from version.txt at build time
const version = fs.readFileSync('../version.txt', 'utf8').trim();

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

  // Enable Mermaid diagrams in markdown
  markdown: {
    mermaid: true,
  },

  presets: [
    [
      'classic',
      {
        docs: {
          sidebarPath: './sidebars.ts',
          editUrl: `https://github.com/${GITHUB_ORG}/${GITHUB_REPO}/tree/main/website/`,
        },
        blog: {
          showReadingTime: true,
          blogTitle: 'DevContainer Toolbox Blog',
          blogDescription: 'Sovereign development tools for Norwegian digital resilience',
          postsPerPage: 10,
          blogSidebarTitle: 'Recent posts',
          blogSidebarCount: 5,
          editUrl: `https://github.com/${GITHUB_ORG}/${GITHUB_REPO}/tree/main/website/`,
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
    announcementBar: {
      id: 'v1_4_announcement',
      content: '📚 New documentation site! <a href="/devcontainer-toolbox/docs/getting-started">Get started</a>',
      backgroundColor: '#25c2a0',
      textColor: '#fff',
      isCloseable: true,
    },
    image: 'img/social-card.jpg',
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
          to: '/blog',
          label: 'Blog',
          position: 'left',
        },
        {
          type: 'html',
          position: 'right',
          value: `<span class="badge badge--secondary">v${version}</span>`,
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
            {
              label: 'About',
              to: '/docs/about',
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
          title: 'SovereignSky',
          items: [
            {
              label: 'SovereignSky Initiative',
              href: 'https://sovereignsky.no',
            },
            {
              label: 'helpers.no',
              href: 'https://helpers.no',
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
      copyright: `Copyright © ${new Date().getFullYear()} DevContainer Toolbox. Part of the <a href="https://sovereignsky.no" target="_blank" rel="noopener noreferrer">SovereignSky</a> initiative.`,
    },
    prism: {
      theme: prismThemes.github,
      darkTheme: prismThemes.dracula,
      additionalLanguages: ['bash', 'powershell', 'json'],
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
