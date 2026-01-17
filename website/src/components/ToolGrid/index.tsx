import type {ReactNode} from 'react';
import Link from '@docusaurus/Link';
import ToolCard, {Tool} from '../ToolCard';
import toolsData from '@site/src/data/tools.json';
import styles from './styles.module.css';

type ToolGridProps = {
  category?: string;
  limit?: number;
  showViewAll?: boolean;
  showTags?: boolean;
  title?: string;
  columns?: 2 | 3 | 4;
};

export default function ToolGrid({
  category,
  limit,
  showViewAll = false,
  showTags = false,
  title,
  columns,
}: ToolGridProps): ReactNode {
  const {tools} = toolsData as {tools: Tool[]};

  let filteredTools = category
    ? tools.filter((tool) => tool.category === category)
    : tools;

  const totalCount = filteredTools.length;

  if (limit && limit > 0) {
    filteredTools = filteredTools.slice(0, limit);
  }

  if (filteredTools.length === 0) {
    return null;
  }

  const gridClassName = columns
    ? `${styles.toolGrid} ${styles[`columns${columns}`]}`
    : styles.toolGrid;

  return (
    <div className={styles.toolGridContainer}>
      {title && (
        <h3 className={styles.gridTitle}>
          {title}
          {category && <span className={styles.toolCount}>{totalCount} tools</span>}
        </h3>
      )}
      <div className={gridClassName}>
        {filteredTools.map((tool) => (
          <ToolCard key={tool.id} tool={tool} showTags={showTags} />
        ))}
      </div>
      {showViewAll && limit && totalCount > limit && (
        <div className={styles.viewAllContainer}>
          <Link to="/docs/tools-details" className={styles.viewAllLink}>
            View All {totalCount} Tools &rarr;
          </Link>
        </div>
      )}
    </div>
  );
}
