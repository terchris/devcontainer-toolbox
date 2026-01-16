import type {ReactNode} from 'react';
import Link from '@docusaurus/Link';
import useBaseUrl from '@docusaurus/useBaseUrl';
import {getToolPath} from '@site/src/utils/anchors';
import styles from './styles.module.css';

export type Tool = {
  id: string;
  type: string;
  name: string;
  description: string;
  category: string;
  tags: string[];
  abstract: string;
  logo: string;
  website: string;
  summary: string;
  related: string[];
};

type ToolCardProps = {
  tool: Tool;
  showTags?: boolean;
};

export default function ToolCard({tool, showTags = false}: ToolCardProps): ReactNode {
  const logoPath = useBaseUrl(`/img/tools/${tool.logo}`);
  const detailPath = getToolPath(tool.id, tool.category);

  return (
    <div className={styles.toolCard}>
      <div className={styles.logoContainer}>
        <img
          src={logoPath}
          alt={`${tool.name} logo`}
          className={styles.logo}
          loading="lazy"
        />
      </div>
      <div className={styles.content}>
        <Link to={detailPath} className={styles.title}>
          {tool.name}
        </Link>
        <p className={styles.abstract}>{tool.abstract}</p>
        {showTags && tool.tags.length > 0 && (
          <div className={styles.tags}>
            {tool.tags.slice(0, 4).map((tag) => (
              <span key={tag} className={styles.tag}>
                {tag}
              </span>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
