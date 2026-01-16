import type {ReactNode} from 'react';
import Link from '@docusaurus/Link';
import useBaseUrl from '@docusaurus/useBaseUrl';
import {getToolPath} from '@site/src/utils/anchors';
import toolsData from '@site/src/data/tools.json';
import styles from './styles.module.css';

type Tool = {
  id: string;
  name: string;
  category: string;
  abstract: string;
  logo: string;
};

type RelatedToolsProps = {
  relatedIds: string[];
  title?: string;
};

export default function RelatedTools({
  relatedIds,
  title = 'Related Tools',
}: RelatedToolsProps): ReactNode {
  const {tools} = toolsData as {tools: Tool[]};
  const toolsImgBase = useBaseUrl('/img/tools/');

  // Find tools by ID
  const relatedTools = relatedIds
    .map((id) => tools.find((tool) => tool.id === id))
    .filter((tool): tool is Tool => tool !== undefined);

  if (relatedTools.length === 0) {
    return null;
  }

  return (
    <div className={styles.relatedToolsContainer}>
      {title && <h4 className={styles.title}>{title}</h4>}
      <div className={styles.scrollContainer}>
        {relatedTools.map((tool) => {
          const logoPath = `${toolsImgBase}${tool.logo}`;
          const detailPath = getToolPath(tool.id, tool.category);

          return (
            <Link key={tool.id} to={detailPath} className={styles.miniCard}>
              <img
                src={logoPath}
                alt={`${tool.name} logo`}
                className={styles.logo}
                loading="lazy"
              />
              <div className={styles.cardContent}>
                <span className={styles.cardTitle}>{tool.name}</span>
                <span className={styles.cardAbstract}>{tool.abstract}</span>
              </div>
            </Link>
          );
        })}
      </div>
    </div>
  );
}
