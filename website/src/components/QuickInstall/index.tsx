import type {ReactNode} from 'react';
import CodeBlock from '@theme/CodeBlock';
import styles from './styles.module.css';

export default function QuickInstall(): ReactNode {
  return (
    <section className={styles.quickInstall}>
      <div className="container">
        <h2 className="text--center">Quick Install</h2>
        <p className="text--center">
          Add devcontainer-toolbox to any project with a single command:
        </p>
        <div className={styles.codeBlocks}>
          <div className={styles.codeBlock}>
            <p><strong>Mac/Linux</strong></p>
            <CodeBlock language="bash">
              curl -fsSL https://raw.githubusercontent.com/terchris/devcontainer-toolbox/main/install.sh | bash
            </CodeBlock>
          </div>
          <div className={styles.codeBlock}>
            <p><strong>Windows PowerShell</strong></p>
            <CodeBlock language="powershell">
              irm https://raw.githubusercontent.com/terchris/devcontainer-toolbox/main/install.ps1 | iex
            </CodeBlock>
          </div>
        </div>
      </div>
    </section>
  );
}
