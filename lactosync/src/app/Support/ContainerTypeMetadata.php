<?php

namespace App\Support;

use Illuminate\Validation\ValidationException;

class ContainerTypeMetadata
{
    /**
     * @return array{name: string, kind: string, size_ml: int, size_key: string}
     */
    public static function resolve(string $name, ?string $kind = null, ?string $size = null): array
    {
        $resolvedKind = $kind ?? self::kindFromName($name);
        $sizeToken = $size !== null && $size !== '' ? trim($size) : self::sizeTokenFromName($name);

        if ($sizeToken === null) {
            throw ValidationException::withMessages([
                'size' => ['Enter a valid size like 3L, 1.5L, or 500ml.'],
            ]);
        }

        [$sizeMl, $sizeKey] = self::parseSizeToken($sizeToken);

        return [
            'name' => trim($name),
            'kind' => $resolvedKind,
            'size_ml' => $sizeMl,
            'size_key' => $sizeKey,
        ];
    }

    public static function buildName(string $kind, string $size): string
    {
        $label = $kind === 'glass_bottle' ? 'Glass Bottle' : 'Plastic Bag';

        return $label.' '.trim($size);
    }

    private static function kindFromName(string $name): string
    {
        return str_contains(strtolower($name), 'glass') ? 'glass_bottle' : 'plastic_bag';
    }

    private static function sizeTokenFromName(string $name): ?string
    {
        if (preg_match('/(\d+(?:\.\d+)?)\s*l\b/i', $name, $matches)) {
            $litres = (float) $matches[1];

            return fmod($litres, 1.0) === 0.0
                ? ((int) $litres).'L'
                : $litres.'L';
        }

        if (preg_match('/(\d+)\s*ml\b/i', $name, $matches)) {
            return $matches[1].'ml';
        }

        return null;
    }

    /**
     * @return array{0: int, 1: string}
     */
    private static function parseSizeToken(string $token): array
    {
        if (preg_match('/^(\d+(?:\.\d+)?)\s*l$/i', $token, $matches)) {
            $litres = (float) $matches[1];
            $sizeMl = (int) round($litres * 1000);
            $sizeKey = fmod($litres, 1.0) === 0.0
                ? ((int) $litres).'L'
                : $litres.'L';

            return [$sizeMl, $sizeKey];
        }

        if (preg_match('/^(\d+)\s*ml$/i', $token, $matches)) {
            return [(int) $matches[1], $matches[1].'ml'];
        }

        throw ValidationException::withMessages([
            'size' => ['Enter a valid size like 3L, 1.5L, or 500ml.'],
        ]);
    }
}
