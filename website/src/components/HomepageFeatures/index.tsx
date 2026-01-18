import type {ReactNode} from 'react';
import clsx from 'clsx';
import Link from '@docusaurus/Link';
import useBaseUrl from '@docusaurus/useBaseUrl';
import Heading from '@theme/Heading';
import styles from './styles.module.css';

type FeatureItem = {
  title: string;
  image: string;
  description: ReactNode;
  link: string;
};

const FeatureList: FeatureItem[] = [
  {
    title: 'Works Everywhere',
    image: '/img/works-everywhere.png',
    description: (
      <>
        Same environment on Windows, Mac, and Linux. No more "works on my machine" problems.
      </>
    ),
    link: '/docs/what-are-devcontainers',
  },
  {
    title: '20+ Tools Ready',
    image: '/img/tools-ready.png',
    description: (
      <>
        Python, Go, TypeScript, Azure, Kubernetes, AI tools and more. Install with one click via the interactive menu.
      </>
    ),
    link: '/tools',
  },
  {
    title: 'AI-Ready Development',
    image: '/img/ai-ready.png',
    description: (
      <>
        Safely run AI coding assistants inside the container. They can only access your project, not your whole machine.
      </>
    ),
    link: '/docs/ai-development/',
  },
];

function Feature({title, image, description, link}: FeatureItem) {
  const imgUrl = useBaseUrl(image);
  return (
    <div className={clsx('col col--4')}>
      <Link to={link} className={styles.featureLink}>
        <div className="text--center">
          <img src={imgUrl} alt={title} className={styles.featureImg} />
        </div>
        <div className="text--center padding-horiz--md">
          <Heading as="h3">{title}</Heading>
          <p>{description}</p>
        </div>
      </Link>
    </div>
  );
}

export default function HomepageFeatures(): ReactNode {
  return (
    <section className={styles.features}>
      <div className="container">
        <div className="row">
          {FeatureList.map((props, idx) => (
            <Feature key={idx} {...props} />
          ))}
        </div>
      </div>
    </section>
  );
}
