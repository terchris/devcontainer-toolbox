import type {ReactNode} from 'react';
import Link from '@docusaurus/Link';
import useBaseUrl from '@docusaurus/useBaseUrl';
import {getCategoryFolder} from '@site/src/utils/anchors';
import styles from './styles.module.css';

export type Category = {
  id: string;
  name: string;
  order: number;
  tags: string[];
  abstract: string;
  summary: string;
  logo: string;
};

type CategoryCardProps = {
  category: Category;
  toolCount: number;
};

export default function CategoryCard({category, toolCount}: CategoryCardProps): ReactNode {
  const logoPath = useBaseUrl(`/img/categories/${category.logo}`);
  const categoryPath = `/docs/tools/${getCategoryFolder(category.id)}`;

  return (
    <Link to={categoryPath} className={styles.categoryCard}>
      <div className={styles.logoContainer}>
        <img
          src={logoPath}
          alt={`${category.name} logo`}
          className={styles.logo}
          loading="lazy"
        />
      </div>
      <div className={styles.content}>
        <h4 className={styles.title}>{category.name}</h4>
        <p className={styles.abstract}>{category.abstract}</p>
        <span className={styles.toolCount}>
          {toolCount} {toolCount === 1 ? 'tool' : 'tools'}
        </span>
      </div>
    </Link>
  );
}
