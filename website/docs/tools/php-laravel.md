---
title: PHP Laravel Development
sidebar_position: 3
---

# PHP Laravel Development

Complete PHP and Laravel development environment with PHP 8.4, Composer, Laravel installer, and VS Code extensions optimized for Laravel development.

## What Gets Installed

### Runtime & Tools

| Tool | Description |
|------|-------------|
| PHP 8.4 | Latest PHP runtime via Laravel Herd-lite |
| Composer | PHP dependency manager |
| Laravel Installer | CLI tool for creating new Laravel projects |

### VS Code Extensions

| Extension | Description |
|-----------|-------------|
| PHP Intelephense | Advanced PHP language support with IntelliSense |
| PHP Debug | Debug PHP applications using Xdebug |
| PHP DocBlocker | Automatically generate PHPDoc comments |
| Composer | Composer dependency manager integration |
| PHP Namespace Resolver | Auto-import and resolve PHP namespaces |
| Laravel Blade Snippets | Blade syntax highlighting and snippets |
| Laravel Artisan | Run Laravel Artisan commands from VS Code |

## Installation

Install via the interactive menu:

```bash
dev-setup
```

Or install directly:

```bash
.devcontainer/additions/install-dev-php-laravel.sh
```

:::note
After installation, run `source ~/.bashrc` to update your PATH.
:::

To uninstall:

```bash
.devcontainer/additions/install-dev-php-laravel.sh --uninstall
```

## How to Use

### Creating a New Laravel Project

```bash
# Using Laravel installer
laravel new my-project

# Or using Composer
composer create-project laravel/laravel my-project
```

### Starting the Development Server

```bash
cd my-project

# Start all services (Laravel + Vite + Queue + Logs)
composer run dev

# Or start just the Laravel server
php artisan serve
```

Access your app at `http://localhost:8000`

### Common Artisan Commands

```bash
# Interactive PHP shell
php artisan tinker

# Run database migrations
php artisan migrate

# Create a new controller
php artisan make:controller UserController

# Create a new model with migration
php artisan make:model Post -m

# Run tests
composer run test
# or
php artisan test
```

## Example Workflows

### Setting Up a New Project

```bash
# Create new Laravel project
laravel new my-app
cd my-app

# Set up environment
cp .env.example .env
php artisan key:generate

# Create SQLite database (default in Laravel 11+)
touch database/database.sqlite

# Run migrations
php artisan migrate

# Start development
composer run dev
```

### Working with an Existing Project

When you open an existing Laravel project in the devcontainer, the installer automatically:

1. Installs Composer dependencies (`composer install`)
2. Installs npm dependencies (`npm install`)
3. Creates `.env` from `.env.example` if missing
4. Generates application key if missing
5. Creates SQLite database file if configured
6. Runs migrations if database is empty
7. Configures Vite for devcontainer compatibility

### Database Operations

```bash
# Run migrations
php artisan migrate

# Rollback last migration
php artisan migrate:rollback

# Seed the database
php artisan db:seed

# Fresh migration with seeding
php artisan migrate:fresh --seed
```

## Devcontainer Configuration

### Vite Configuration

For hot module replacement (HMR) to work in devcontainers, `vite.config.js` needs specific settings. The installer can configure this automatically, or you can add manually:

```javascript
// vite.config.js
export default defineConfig({
    server: {
        host: '0.0.0.0',
        port: 5173,
        hmr: {
            host: 'localhost'
        }
    },
    // ... rest of config
});
```

### Port Configuration

| Port | Service |
|------|---------|
| 8000 | Laravel application (main) |
| 5173 | Vite dev server (assets) |

:::tip
Use port 8000 in your browser - Vite runs in the background for asset compilation.
:::

## Troubleshooting

### PHP Not Found After Installation

Reload your shell to update PATH:

```bash
source ~/.bashrc
```

### Vite Assets Not Loading

1. Check that `composer run dev` is running (not just `php artisan serve`)
2. Verify `vite.config.js` has `host: '0.0.0.0'`
3. Ensure both ports 8000 and 5173 are forwarded

### Database Connection Issues

For SQLite:
```bash
touch database/database.sqlite
```

Update `.env`:
```
DB_CONNECTION=sqlite
```

### Permission Issues

```bash
chmod -R 775 storage bootstrap/cache
```

## Additional Tools

For database management and API testing, install the Development Utilities:

```bash
.devcontainer/additions/install-tool-dev-utils.sh
```

This adds SQLTools for database management and REST Client for API testing.

## Documentation

- [Laravel Documentation](https://laravel.com/docs/)
- [PHP Documentation](https://www.php.net/docs.php)
- [Composer Documentation](https://getcomposer.org/doc/)
