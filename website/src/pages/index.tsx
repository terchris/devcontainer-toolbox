import type {ReactNode} from 'react';
import Link from '@docusaurus/Link';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import useBaseUrl from '@docusaurus/useBaseUrl';
import Layout from '@theme/Layout';
import HomepageFeatures from '@site/src/components/HomepageFeatures';
import QuickInstall from '@site/src/components/QuickInstall';
import AiDemo from '@site/src/components/AiDemo';
import FloatingCubes from '@site/src/components/FloatingCubes';
import Heading from '@theme/Heading';

import styles from './index.module.css';

function HomepageHeader() {
  const {siteConfig} = useDocusaurusContext();
  const githubUrl = `https://github.com/${siteConfig.organizationName}/${siteConfig.projectName}`;
  const logoUrl = useBaseUrl('/img/brand/cube-code-green.svg');

  return (
    <header className={styles.heroSection}>
      <div className={styles.heroContainer}>
        {/* Left side - Floating Cubes */}
        <div className={styles.heroLeft}>
          <FloatingCubes />
        </div>

        {/* Right side - Text and CTAs */}
        <div className={styles.heroRight}>
          <img
            src={logoUrl}
            alt="DevContainer Toolbox"
            className={styles.heroLogo}
          />
          <Heading as="h1" className={styles.heroTitle}>
            {siteConfig.title}
          </Heading>
          <p className={styles.heroTagline}>
            One command.<br />
            Full dev environment.<br />
            Any project.
          </p>
          <div className={styles.heroButtons}>
            <Link
              className={styles.primaryButton}
              to="/docs/">
              Get Started
            </Link>
            <Link
              className={styles.secondaryButton}
              href={githubUrl}>
              View on GitHub
            </Link>
          </div>
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
      description="One command. Full dev environment. Any project.">
      <HomepageHeader />
      <main>
        <HomepageFeatures />
        <QuickInstall />
        <AiDemo />
      </main>
    </Layout>
  );
}
