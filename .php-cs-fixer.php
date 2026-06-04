<?php

use PhpCsFixer\Config;
use PhpCsFixer\Finder;

$finder = Finder::create()
    ->in([__DIR__ . '/src'])
    ->exclude(['var']);

return (new Config())
    ->setRules([
        '@PSR12' => true,
        '@PHP8x2Migration' => true,
    ])
    ->setFinder($finder);
