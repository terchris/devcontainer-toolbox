import type {ReactNode} from 'react';
import Layout from '@theme/Layout';
import Heading from '@theme/Heading';
import CategoryGrid from '@site/src/components/CategoryGrid';
import ToolGrid from '@site/src/components/ToolGrid';
import categoriesData from '@site/src/data/categories.json';
import styles from './tools.module.css';

type Category = {
  id: string;
  name: string;
  order: number;
};

export default function ToolsPage(): ReactNode {
  const {categories} = categoriesData as {categories: Category[]};

  // Sort categories by order and filter to only those with tools
  const sortedCategories = [...categories].sort((a, b) => a.order - b.order);

  return (
    <Layout
      title="Available Tools"
      description="Browse 20+ development tools for Python, TypeScript, Azure, Kubernetes, AI, and more."
    >
      <main className={styles.toolsPage}>
        <div className="container">
          <header className={styles.header}>
            <Heading as="h1">Available Tools</Heading>
            <p className={styles.subtitle}>
              20+ development tools ready to install. Browse by category or explore all tools below.
            </p>
          </header>

          <section className={styles.section}>
            <CategoryGrid title="Browse by Category" />
          </section>

          {sortedCategories.map((category) => (
            <section key={category.id} className={styles.section}>
              <ToolGrid
                category={category.id}
                title={category.name}
                showTags={false}
              />
            </section>
          ))}
        </div>
      </main>
    </Layout>
  );
}
