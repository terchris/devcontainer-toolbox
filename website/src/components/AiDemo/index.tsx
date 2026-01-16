import type {ReactNode} from 'react';
import Link from '@docusaurus/Link';
import styles from './styles.module.css';

export default function AiDemo(): ReactNode {
  return (
    <section className={styles.aiDemo}>
      <div className="container">
        <h2 className="text--center">AI-Powered Development</h2>
        <p className="text--center">
          Watch Claude Code implement a complete feature from a plan file — safely inside the container.
        </p>
        <div className={styles.gifContainer}>
          <img
            src="/devcontainer-toolbox/img/ai-implement-plan-teaser.gif"
            alt="AI implementing a plan"
            className={styles.demoGif}
          />
        </div>
        <div className="text--center" style={{marginTop: '1.5rem'}}>
          <Link
            className="button button--primary button--lg"
            to="/docs/ai-development">
            Learn More About AI Development
          </Link>
        </div>
      </div>
    </section>
  );
}
