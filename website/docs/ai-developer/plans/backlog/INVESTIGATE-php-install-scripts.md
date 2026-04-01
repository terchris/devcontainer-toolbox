# Investigate: PHP Install Scripts — Split and Fix Instructions

> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) - The implementation process
> - [PLANS.md](../../PLANS.md) - Plan structure and best practices

## Status: Backlog

**Goal**: Fix two problems with PHP tool installation: (1) no simple PHP-only install script exists, and (2) the Laravel install script gives instructions that don't work.

**Priority**: High

**Last Updated**: 2026-03-30

---

## Problem 1: No simple PHP install script

The only PHP install script is `install-dev-php-laravel.sh` which bundles PHP + Composer + Laravel Installer. When a user installs the "PHP Basic Webserver" template (which uses plain PHP with the built-in server), they get Laravel tools they don't need.

PHP developers don't always use Laravel. Common PHP use cases:
- Plain PHP with built-in server (like the basic webserver template)
- Symfony framework
- Slim micro framework (APIs)
- WordPress / Drupal CMS
- Composer-based projects without a framework

**What's needed:** A simple `install-dev-php.sh` that installs PHP + Composer only. Laravel should be a separate, additional script.

### Current state

```
install-dev-php-laravel.sh
  SCRIPT_ID="dev-php-laravel"
  Installs: PHP 8.4, Composer, Laravel Installer
  VS Code extensions: 7 (including Laravel-specific ones)
  Post-install message: assumes Laravel project
```

### Proposed split

```
install-dev-php.sh              (NEW)
  SCRIPT_ID="dev-php"
  Installs: PHP, Composer
  VS Code extensions: PHP Intelephense, PHP Debug, PHP DocBlocker, Composer
  Post-install message: generic PHP instructions

install-dev-php-laravel.sh      (MODIFIED)
  SCRIPT_ID="dev-php-laravel"
  SCRIPT_PREREQUISITES="install-dev-php.sh" (or depends on dev-php)
  Installs: Laravel Installer (on top of dev-php)
  VS Code extensions: Laravel Blade Snippets, Laravel Artisan, PHP Namespace Resolver
  Post-install message: Laravel-specific instructions
```

### Impact on templates

The PHP Basic Webserver template in dev-templates would change:
```bash
# Before
TEMPLATE_TOOLS="dev-php-laravel"

# After
TEMPLATE_TOOLS="dev-php"
```

---

## Problem 2: Laravel install script instructions don't work

After installing the PHP Basic Webserver template, the `install-dev-php-laravel.sh` post-install message says:

```
Next steps:
  1. Run: source ~/.bashrc
  2. Then: composer run dev
  3. Open: http://localhost:8000
```

But `composer run dev` fails because there is no `composer.json` in the workspace — the template is a plain PHP app, not a Laravel project:

```
$ composer run dev
Composer could not find a composer.json file in /workspace
```

Even for a Laravel project, these instructions are wrong — you'd need to create a project first with `laravel new my-project` before `composer run dev` works.

### Root cause

The `post_installation_message()` in `install-dev-php-laravel.sh` assumes:
1. The user is building a Laravel project
2. A Laravel project already exists in the workspace
3. `composer.json` is present

None of these are true right after installing tools.

### Fix options

**Option A:** Make `post_installation_message()` conditional — detect if `composer.json` exists and show different messages.

**Option B:** Make the message generic — "Tools installed. See your project's README for how to run it."

**Option C:** Split into two scripts (Problem 1 fix) — the generic `install-dev-php.sh` shows generic PHP instructions, and `install-dev-php-laravel.sh` shows Laravel-specific instructions that start with "Create a new project first."

---

## Questions to Answer

1. Should `install-dev-php.sh` use the same installation method (php.new/Herd Lite) or install via apt?
2. Should `install-dev-php-laravel.sh` depend on `install-dev-php.sh` via SCRIPT_PREREQUISITES, or bundle everything?
3. Which VS Code extensions belong in the base PHP script vs the Laravel script?
4. Should post-install messages ever assume a project structure, or always be generic?

---

## Recommendation

*To be determined after investigation.*

---

## Next Steps

- [ ] Analyse `install-dev-php-laravel.sh` to understand the installation method
- [ ] Determine how to split PHP from Laravel cleanly
- [ ] Fix post-install message for both scripts
- [ ] Update TEMPLATE_TOOLS in dev-templates PHP template (from `dev-php-laravel` to `dev-php`)
- [ ] Create PLAN with implementation tasks
