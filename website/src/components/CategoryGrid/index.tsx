import type {ReactNode} from 'react';
import CategoryCard, {Category} from '../CategoryCard';
import categoriesData from '@site/src/data/categories.json';
import toolsData from '@site/src/data/tools.json';
import styles from './styles.module.css';

type CategoryGridProps = {
  title?: string;
  excludeEmpty?: boolean;
};

export default function CategoryGrid({
  title,
  excludeEmpty = true,
}: CategoryGridProps): ReactNode {
  const {categories} = categoriesData as {categories: Category[]};
  const {tools} = toolsData as {tools: {category: string; type: string}[]};

  // Count install-type tools per category (config/service scripts don't have detail pages)
  const toolCountByCategory: Record<string, number> = {};
  for (const tool of tools) {
    if (tool.type === 'install') {
      toolCountByCategory[tool.category] = (toolCountByCategory[tool.category] || 0) + 1;
    }
  }

  // Sort by order and optionally filter empty
  let sortedCategories = [...categories].sort((a, b) => a.order - b.order);

  if (excludeEmpty) {
    sortedCategories = sortedCategories.filter(
      (cat) => (toolCountByCategory[cat.id] || 0) > 0
    );
  }

  if (sortedCategories.length === 0) {
    return null;
  }

  return (
    <div className={styles.categoryGridContainer}>
      {title && <h3 className={styles.gridTitle}>{title}</h3>}
      <div className={styles.categoryGrid}>
        {sortedCategories.map((category) => (
          <CategoryCard
            key={category.id}
            category={category}
            toolCount={toolCountByCategory[category.id] || 0}
          />
        ))}
      </div>
    </div>
  );
}
