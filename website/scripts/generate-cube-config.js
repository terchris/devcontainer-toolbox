#!/usr/bin/env node
/**
 * Generate FloatingCubes configuration from available tool logos
 *
 * Usage:
 *   node scripts/generate-cube-config.js           # Normal run
 *   node scripts/generate-cube-config.js --verbose # Show all image details
 *   npm run generate:cubes                         # Via npm script
 *
 * This script:
 * 1. Scans static/img/tools/ for available logo files (.webp or .svg with -logo suffix)
 * 2. Validates each image:
 *    - WebP: max 50KB file size, 64-512px dimensions
 *    - SVG: max 100KB file size, min 64px dimensions (no max, vectors scale)
 *    - Warns if not square
 * 3. Reads src/data/tools.json for display names
 * 4. Generates a TypeScript configuration file for FloatingCubes
 *
 * Supported formats: .webp, .svg
 * Invalid images are excluded and reported. Fix issues and re-run to include them.
 */

const fs = require('fs');
const path = require('path');

const WEBSITE_DIR = path.join(__dirname, '..');
const TOOLS_DIR = path.join(WEBSITE_DIR, 'static/img/tools');
const TOOLS_JSON = path.join(WEBSITE_DIR, 'src/data/tools.json');
const OUTPUT_FILE = path.join(WEBSITE_DIR, 'src/components/FloatingCubes/cubeConfig.ts');

// Image validation constraints
const IMAGE_CONSTRAINTS = {
  maxFileSizeKB: 50,              // Maximum file size in KB (for raster images)
  minDimension: 64,               // Minimum width/height in pixels
  maxDimension: 512,              // Maximum width/height in pixels
  allowedFormats: ['webp', 'svg'], // Allowed file formats
};

// Cube layout configuration - positions and sizes for visual appeal
const CUBE_LAYOUTS = [
  { size: 'large', position: { x: 10, y: 25 }, delay: 0 },
  { size: 'medium', position: { x: 55, y: 8 }, delay: 0.5 },
  { size: 'large', position: { x: 35, y: 45 }, delay: 1 },
  { size: 'medium', position: { x: 5, y: 60 }, delay: 1.5 },
  { size: 'small', position: { x: 75, y: 25 }, delay: 2 },
  { size: 'medium', position: { x: 65, y: 55 }, delay: 2.5 },
  { size: 'small', position: { x: 25, y: 80 }, delay: 3 },
  { size: 'small', position: { x: 80, y: 5 }, delay: 0.8 },
];

// Short display names for tools
const SHORT_NAMES = {
  'Python Development Tools': 'Python',
  'Go Runtime & Development Tools': 'Go',
  'TypeScript Development Tools': 'TypeScript',
  'Rust Development Tools': 'Rust',
  'Java Runtime & Development Tools': 'Java',
  'C# Development Tools': 'C#',
  'C/C++ Development Tools': 'C++',
  'Fortran Development Tools': 'Fortran',
  'Bash Development Tools': 'Bash',
  'PHP Laravel Development Tools': 'Laravel',
  'Claude Code': 'Claude',
  'Kubernetes Development Tools': 'Kubernetes',
  'Azure Application Development': 'Azure',
  'Azure Operations & Infrastructure Management': 'Azure Ops',
  'Infrastructure as Code Tools': 'Terraform',
  'API Development Tools': 'API Dev',
  'Data & Analytics Tools': 'Analytics',
  'Databricks Development Tools': 'Databricks',
  'Development Utilities': 'Dev Utils',
  'Okta Identity Management Tools': 'Okta',
  'Microsoft Power Platform Tools': 'Power Platform',
};

// Filename-based short names for logos not in tools.json
const LOGO_SHORT_NAMES = {
  'config-ai-claudecode-logo.webp': 'Claude Config',
  'config-devcontainer-identity-logo.webp': 'Identity',
  'config-git-logo.webp': 'Git',
  'config-host-info-logo.webp': 'Host Info',
  'config-nginx-logo.webp': 'Nginx',
  'config-supervisor-logo.webp': 'Supervisor',
  'srv-nginx-logo.webp': 'Nginx',
  'srv-otel-logo.webp': 'OpenTelemetry',
  'srv-otel-monitoring-logo.webp': 'Monitoring',
  'dev-imagetools-logo.webp': 'ImageTools',
};

/**
 * Get SVG dimensions from viewBox or width/height attributes
 */
function getSVGDimensions(filePath) {
  try {
    const content = fs.readFileSync(filePath, 'utf-8');

    // Try viewBox first
    const viewBoxMatch = content.match(/viewBox=["']([^"']+)["']/i);
    if (viewBoxMatch) {
      const parts = viewBoxMatch[1].trim().split(/[\s,]+/);
      if (parts.length >= 4) {
        const width = parseFloat(parts[2]);
        const height = parseFloat(parts[3]);
        if (!isNaN(width) && !isNaN(height)) {
          return { width: Math.round(width), height: Math.round(height) };
        }
      }
    }

    // Try width/height attributes
    const widthMatch = content.match(/\bwidth=["'](\d+)(?:px)?["']/i);
    const heightMatch = content.match(/\bheight=["'](\d+)(?:px)?["']/i);
    if (widthMatch && heightMatch) {
      return {
        width: parseInt(widthMatch[1], 10),
        height: parseInt(heightMatch[1], 10)
      };
    }

    return null;
  } catch (error) {
    console.error(`Error reading SVG ${filePath}: ${error.message}`);
    return null;
  }
}

/**
 * Get WebP image dimensions by reading the file header
 * WebP format: https://developers.google.com/speed/webp/docs/riff_container
 */
function getWebPDimensions(filePath) {
  try {
    const buffer = fs.readFileSync(filePath);

    // Check RIFF header
    if (buffer.toString('ascii', 0, 4) !== 'RIFF') {
      return null;
    }

    // Check WEBP signature
    if (buffer.toString('ascii', 8, 12) !== 'WEBP') {
      return null;
    }

    // Check chunk type (VP8, VP8L, or VP8X)
    const chunkType = buffer.toString('ascii', 12, 16);

    if (chunkType === 'VP8 ') {
      // Lossy format - dimensions at offset 26-29
      // Skip to frame header (after chunk size)
      const width = (buffer.readUInt16LE(26) & 0x3fff);
      const height = (buffer.readUInt16LE(28) & 0x3fff);
      return { width, height };
    } else if (chunkType === 'VP8L') {
      // Lossless format - dimensions encoded in first 4 bytes after signature
      const signature = buffer.readUInt32LE(21);
      const width = (signature & 0x3fff) + 1;
      const height = ((signature >> 14) & 0x3fff) + 1;
      return { width, height };
    } else if (chunkType === 'VP8X') {
      // Extended format - dimensions at specific offsets
      const width = (buffer.readUIntLE(24, 3) + 1);
      const height = (buffer.readUIntLE(27, 3) + 1);
      return { width, height };
    }

    return null;
  } catch (error) {
    console.error(`Error reading ${filePath}: ${error.message}`);
    return null;
  }
}

/**
 * Get image dimensions based on file type
 */
function getImageDimensions(filePath) {
  const ext = path.extname(filePath).toLowerCase();
  if (ext === '.svg') {
    return getSVGDimensions(filePath);
  } else if (ext === '.webp') {
    return getWebPDimensions(filePath);
  }
  return null;
}

/**
 * Validate an image file against constraints
 * Returns { valid: boolean, errors: string[] }
 */
function validateImage(filePath, filename) {
  const errors = [];
  const ext = path.extname(filename).toLowerCase();
  const isSVG = ext === '.svg';

  // Check file exists
  if (!fs.existsSync(filePath)) {
    return { valid: false, errors: [`File not found: ${filename}`] };
  }

  // Check file size (less strict for SVG since they're vector)
  const stats = fs.statSync(filePath);
  const fileSizeKB = stats.size / 1024;
  const maxSize = isSVG ? IMAGE_CONSTRAINTS.maxFileSizeKB * 2 : IMAGE_CONSTRAINTS.maxFileSizeKB;
  if (fileSizeKB > maxSize) {
    errors.push(`File too large: ${fileSizeKB.toFixed(1)}KB (max: ${maxSize}KB)`);
  }

  // Check dimensions
  const dimensions = getImageDimensions(filePath);
  if (dimensions) {
    const { width, height } = dimensions;

    if (width < IMAGE_CONSTRAINTS.minDimension || height < IMAGE_CONSTRAINTS.minDimension) {
      errors.push(`Image too small: ${width}x${height} (min: ${IMAGE_CONSTRAINTS.minDimension}px)`);
    }

    // Skip max dimension check for SVG (they're vector and scale infinitely)
    if (!isSVG && (width > IMAGE_CONSTRAINTS.maxDimension || height > IMAGE_CONSTRAINTS.maxDimension)) {
      errors.push(`Image too large: ${width}x${height} (max: ${IMAGE_CONSTRAINTS.maxDimension}px)`);
    }

    // Warn if not square (but don't fail)
    if (width !== height) {
      errors.push(`Warning: Image not square: ${width}x${height}`);
    }
  } else {
    // For SVG, missing dimensions is just a warning
    if (isSVG) {
      errors.push(`Warning: Could not read SVG dimensions (missing viewBox/width/height)`);
    } else {
      errors.push(`Could not read image dimensions`);
    }
  }

  // Only fail on actual errors, not warnings
  const actualErrors = errors.filter(e => !e.startsWith('Warning:'));
  return {
    valid: actualErrors.length === 0,
    errors,
    dimensions,
    fileSizeKB,
    format: ext.replace('.', '')
  };
}

function getShortName(fullName) {
  return SHORT_NAMES[fullName] || fullName.split(' ')[0];
}

function formatName(slug) {
  // Convert slug to title case
  return slug
    .split('-')
    .map(word => word.charAt(0).toUpperCase() + word.slice(1))
    .join(' ');
}

function getDisplayName(filename, toolsData) {
  // Check logo-specific short names first
  if (LOGO_SHORT_NAMES[filename]) {
    return LOGO_SHORT_NAMES[filename];
  }

  // Find matching tool by logo filename
  const tool = toolsData.find(t => t.logo === filename);
  if (tool) {
    return getShortName(tool.name);
  }

  // Fallback: Extract name from filename
  const match = filename.match(/^(?:dev|tool|config|srv)-(.+)-logo\.webp$/);
  if (match) {
    return formatName(match[1]);
  }

  return filename.replace(/-logo\.webp$/, '');
}

function loadToolsData() {
  try {
    const data = JSON.parse(fs.readFileSync(TOOLS_JSON, 'utf-8'));
    return data.tools.map(t => ({
      id: t.id,
      name: t.name,
      logo: t.logo,
    }));
  } catch (error) {
    console.warn('Warning: Could not load tools.json, using filename-based names');
    return [];
  }
}

function getLogoFiles(validateImages = true) {
  const files = fs.readdirSync(TOOLS_DIR);

  // Find logo files with supported formats (.webp or .svg)
  const logoFiles = files
    .filter(f => {
      const ext = path.extname(f).toLowerCase();
      return (ext === '.webp' || ext === '.svg') && f.includes('-logo');
    })
    .sort();

  if (!validateImages) {
    return { logos: logoFiles, validationResults: [] };
  }

  // Validate each image
  const validationResults = [];
  const validLogos = [];

  for (const filename of logoFiles) {
    const filePath = path.join(TOOLS_DIR, filename);
    const result = validateImage(filePath, filename);
    validationResults.push({ filename, ...result });

    if (result.valid) {
      validLogos.push(filename);
    }
  }

  return { logos: validLogos, validationResults, allLogos: logoFiles };
}

function generateCubeConfigs(logos, toolsData) {
  const cubes = [];
  const logosWithNames = logos.map(logo => ({
    logo,
    name: getDisplayName(logo, toolsData),
  }));

  // Shuffle logos for variety (but use a seeded approach for consistency)
  const shuffled = [...logosWithNames].sort((a, b) => {
    // Group by category prefix for visual variety
    const prefixA = a.logo.split('-')[0];
    const prefixB = b.logo.split('-')[0];
    if (prefixA !== prefixB) return prefixA.localeCompare(prefixB);
    return a.logo.localeCompare(b.logo);
  });

  // Interleave different categories
  const categories = { dev: [], tool: [], config: [], srv: [] };
  shuffled.forEach(item => {
    const prefix = item.logo.split('-')[0];
    if (categories[prefix]) {
      categories[prefix].push(item);
    } else {
      categories.dev.push(item); // Default to dev
    }
  });

  // Create interleaved list
  const interleaved = [];
  const maxLen = Math.max(...Object.values(categories).map(arr => arr.length));
  for (let i = 0; i < maxLen; i++) {
    for (const cat of ['dev', 'tool', 'config', 'srv']) {
      if (categories[cat][i]) {
        interleaved.push(categories[cat][i]);
      }
    }
  }

  // Each cube needs 5 logos (top, front, back, left, right)
  const numCubes = Math.min(CUBE_LAYOUTS.length, Math.floor(interleaved.length / 5));

  for (let i = 0; i < numCubes; i++) {
    const layout = CUBE_LAYOUTS[i];
    const startIdx = i * 5;

    // Get 5 logos for this cube
    const cubeLogos = interleaved.slice(startIdx, startIdx + 5);

    // If we don't have enough logos, wrap around
    while (cubeLogos.length < 5) {
      cubeLogos.push(interleaved[cubeLogos.length % interleaved.length]);
    }

    cubes.push({
      logos: {
        top: cubeLogos[0].logo,
        front: cubeLogos[1].logo,
        back: cubeLogos[2].logo,
        left: cubeLogos[3].logo,
        right: cubeLogos[4].logo,
      },
      names: {
        top: cubeLogos[0].name,
        front: cubeLogos[1].name,
        back: cubeLogos[2].name,
        left: cubeLogos[3].name,
        right: cubeLogos[4].name,
      },
      size: layout.size,
      position: layout.position,
      delay: layout.delay,
    });
  }

  return cubes;
}

function generateTypeScriptFile(cubes) {
  const cubesJson = JSON.stringify(cubes, null, 2);

  return `/**
 * Auto-generated FloatingCubes configuration
 * Generated by: node scripts/generate-cube-config.js
 * Generated at: ${new Date().toISOString()}
 *
 * DO NOT EDIT MANUALLY - Run the generator script to update
 */

export type CubeConfig = {
  logos: {
    top: string;
    front: string;
    back: string;
    left: string;
    right: string;
  };
  names: {
    top: string;
    front: string;
    back: string;
    left: string;
    right: string;
  };
  size: 'small' | 'medium' | 'large';
  position: { x: number; y: number };
  delay: number;
};

export const defaultCubes: CubeConfig[] = ${cubesJson};
`;
}

function main() {
  const verbose = process.argv.includes('--verbose') || process.argv.includes('-v');

  console.log('Generating FloatingCubes configuration...\n');

  // Load tool metadata
  const toolsData = loadToolsData();
  console.log(`Loaded ${toolsData.length} tools from tools.json`);

  // Get and validate logos
  const { logos, validationResults, allLogos } = getLogoFiles(true);
  console.log(`Found ${allLogos.length} logo files in ${TOOLS_DIR}`);

  // Report validation results
  const invalidImages = validationResults.filter(r => !r.valid);
  const warnings = validationResults.filter(r => r.valid && r.errors.length > 0);

  if (invalidImages.length > 0) {
    console.log('\n\x1b[31m❌ INVALID IMAGES (excluded from cubes):\x1b[0m');
    invalidImages.forEach(({ filename, errors, fileSizeKB, dimensions }) => {
      const size = dimensions ? `${dimensions.width}x${dimensions.height}` : 'unknown';
      console.log(`  ${filename} (${fileSizeKB?.toFixed(1) || '?'}KB, ${size})`);
      errors.forEach(e => console.log(`    - ${e}`));
    });
  }

  if (warnings.length > 0) {
    console.log('\n\x1b[33m⚠️  WARNINGS:\x1b[0m');
    warnings.forEach(({ filename, errors }) => {
      errors.filter(e => e.startsWith('Warning:')).forEach(e => {
        console.log(`  ${filename}: ${e.replace('Warning: ', '')}`);
      });
    });
  }

  // Show valid images summary
  const validImages = validationResults.filter(r => r.valid);
  if (validImages.length > 0) {
    console.log(`\n\x1b[32m✓ ${validImages.length} valid logos\x1b[0m`);

    if (verbose) {
      console.log('\nImage details:');
      validImages.forEach(({ filename, fileSizeKB, dimensions, format }) => {
        const size = dimensions ? `${dimensions.width}x${dimensions.height}` : 'unknown';
        console.log(`  ${filename}: ${fileSizeKB.toFixed(1)}KB, ${size}, ${format}`);
      });
    }
  }

  if (logos.length === 0) {
    console.error('\n\x1b[31mError: No valid logo files found\x1b[0m');
    process.exit(1);
  }

  // Generate cube configurations
  const cubes = generateCubeConfigs(logos, toolsData);
  console.log(`Generated ${cubes.length} cube configurations`);

  // Write output file
  const output = generateTypeScriptFile(cubes);
  fs.writeFileSync(OUTPUT_FILE, output);
  console.log(`\nWritten to: ${OUTPUT_FILE}`);

  // Print summary
  console.log('\nCube summary:');
  cubes.forEach((cube, i) => {
    console.log(`  Cube ${i + 1} (${cube.size}): ${Object.values(cube.names).join(', ')}`);
  });

  console.log(`\nTotal logos used: ${cubes.length * 5}`);
  console.log(`Valid logos: ${logos.length}/${allLogos.length}`);

  // Exit with error if there were invalid images
  if (invalidImages.length > 0) {
    console.log('\n\x1b[33mNote: Fix invalid images and re-run to include them.\x1b[0m');
  }
}

main();
