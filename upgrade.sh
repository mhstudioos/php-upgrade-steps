#!/usr/bin/env bash
set -euo pipefail

# === Config ===
TOOLS_DIR="./tools"
SRC_DIR="./src"
RECTOR_CONFIG="./rector.php"

# === Rector config genereren indien ontbreekt ===
if [ ! -f "$RECTOR_CONFIG" ]; then
  cat > "$RECTOR_CONFIG" <<'EOF'
<?php
declare(strict_types=1);

use Rector\Config\RectorConfig;
use Rector\Set\ValueObject\LevelSetList;

return static function (RectorConfig $rectorConfig): void {
    $rectorConfig->paths([__DIR__ . '/src', __DIR__ . '/public', __DIR__ . '/app']);
    $rectorConfig->sets([
        LevelSetList::UP_TO_PHP_74,
        LevelSetList::UP_TO_PHP_80,
        LevelSetList::UP_TO_PHP_81,
        LevelSetList::UP_TO_PHP_82,
        LevelSetList::UP_TO_PHP_83,
        LevelSetList::UP_TO_PHP_84,
    ]);
};
EOF
  echo "rector.php aangemaakt ✅"
fi

# === Tools downloaden ===
mkdir -p "$TOOLS_DIR"
download_tool() {
    local url=$1
    local file=$2
    if [ ! -f "$TOOLS_DIR/$file" ]; then
        echo "Downloading $file..."
        curl -sSL -o "$TOOLS_DIR/$file" "$url"
        chmod +x "$TOOLS_DIR/$file"
    fi
}

download_tool "https://github.com/rectorphp/rector/releases/latest/download/rector.phar" "rector.phar"
download_tool "https://cs.symfony.com/download/php-cs-fixer-v3.phar" "php-cs-fixer.phar"
download_tool "https://github.com/phpstan/phpstan/releases/latest/download/phpstan.phar" "phpstan.phar"
download_tool "https://github.com/squizlabs/PHP_CodeSniffer/releases/latest/download/phpcbf.phar" "phpcbf.phar"

# === Stap 2: automatische upgrades en linting ===
echo "== Rector: PHP 7.3 → 8.4 transforms =="
php "$TOOLS_DIR/rector.phar" process "$SRC_DIR" --ansi || true

echo "== PHP-CS-Fixer: stijl & moderne syntax =="
php "$TOOLS_DIR/php-cs-fixer.phar" fix "$SRC_DIR" --allow-risky=yes --verbose || true

echo "== PHPStan: statische analyse =="
php "$TOOLS_DIR/phpstan.phar" analyse "$SRC_DIR" --level=max || true

echo "== PHPCBF: coding standards fix (PSR-12) =="
php "$TOOLS_DIR/phpcbf.phar" --standard=PSR12 "$SRC_DIR" || true

# === Stap 4: gerichte checks & auto-fixes ===
echo "== Extra checks & auto-fixes =="

# Curly brace array offsets → [] vervangen
echo "Fixing curly brace offsets..."
grep -rlP '\$\w+\{' "$SRC_DIR" | while read -r file; do
  sed -E -i.bak 's/([A-Za-z0-9_\$]+)\{([^}]+)\}/\1[\2]/g' "$file"
done

# Implode verkeerde volgorde → omdraaien
echo "Fixing implode argument order..."
grep -rlP 'implode\(\s*\$[A-Za-z_]\w*\s*,\s*\$[A-Za-z_]\w*\s*\)' "$SRC_DIR" | while read -r file; do
  sed -E -i.bak 's/implode\(\s*(\$\w+)\s*,\s*(\$\w+)\s*\)/implode(\2, \1)/g' "$file"
done

# Dynamische properties enkel tonen
echo "Checking for dynamic properties (manual fix needed)..."
rg -n --pcre2 '->\w+\s*=' "$SRC_DIR" || true

echo "== Upgrade script klaar ✅ =="
