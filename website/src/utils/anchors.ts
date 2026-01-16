/**
 * Generates a URL-safe anchor/slug from a heading text.
 * Matches Docusaurus's default anchor generation behavior.
 *
 * @param text - The heading text to convert
 * @returns The anchor string (without the # prefix)
 */
export function generateAnchor(text: string): string {
  return text
    .toLowerCase()
    .replace(/\s+/g, '-') // Replace spaces with hyphens
    .replace(/[^a-z0-9-]/g, '') // Remove non-alphanumeric except hyphens
    .replace(/^-+|-+$/g, ''); // Trim leading/trailing hyphens
}

/**
 * Maps category ID to folder name for URL paths.
 * Must match the mapping in dev-docs.sh get_category_folder()
 */
export function getCategoryFolder(category: string): string {
  const mapping: Record<string, string> = {
    LANGUAGE_DEV: 'development-tools',
    AI_TOOLS: 'ai-machine-learning',
    CLOUD_TOOLS: 'cloud-infrastructure',
    DATA_ANALYTICS: 'data-analytics',
    INFRA_CONFIG: 'infrastructure-configuration',
  };
  return mapping[category] || category.toLowerCase();
}

/**
 * Gets the tool filename from tool ID (strips common prefixes).
 * Must match the logic in dev-docs.sh get_tool_filename()
 */
export function getToolFilename(toolId: string): string {
  return toolId
    .replace(/^dev-/, '')
    .replace(/^tool-/, '')
    .replace(/^install-/, '');
}

/**
 * Generates the full path to a tool's detail page.
 */
export function getToolPath(toolId: string, category: string): string {
  const folder = getCategoryFolder(category);
  const filename = getToolFilename(toolId);
  return `/docs/tools/${folder}/${filename}`;
}
