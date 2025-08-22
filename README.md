# php-upgrade-steps

    curl -L -o tools/rector.phar https://github.com/rectorphp/rector/releases/latest/download/rector.phar
    curl -L -o tools/php-cs-fixer.phar https://cs.symfony.com/download/php-cs-fixer-v3.phar
    curl -L -o tools/phpstan.phar https://github.com/phpstan/phpstan/releases/latest/download/phpstan.phar
    curl -L -o tools/phpcbf.phar https://github.com/squizlabs/PHP_CodeSniffer/releases/latest/download/phpcbf.phar
    chmod +x tools/*.phar

Rector config (rector.php):

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


    php tools/rector.phar process
    php tools/php-cs-fixer.phar fix .
    php tools/phpstan.phar analyse src --level=max


    # Curly brace offsets (7.4 deprec, 8.0 removal)
    rg -n --pcre2 '\$\w+\{\s*[^}]+' src
    
    # Dynamische properties (8.2 deprec)
    rg -n --pcre2 '->\w+\s*=' src
    
    # Tentative return types (8.1)
    rg -n --pcre2 'class\s+\w+.*implements|extends' src
    # (combineer met php -l en runtime deprecation logs)
    
    # Verkeerde implode volgorde (oude code)
    rg -n --pcre2 'implode\(\s*\$[a-zA-Z_]\w*\s*,\s*\$[a-zA-Z_]\w*\s*\)' src






