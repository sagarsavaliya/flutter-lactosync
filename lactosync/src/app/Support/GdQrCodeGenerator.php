<?php

namespace App\Support;

use BaconQrCode\Common\ErrorCorrectionLevel;
use BaconQrCode\Encoder\Encoder;
use RuntimeException;

/** PNG QR codes using GD only (no Imagick). */
final class GdQrCodeGenerator
{
    public static function savePng(string $content, string $absolutePath, int $pixelSize = 480, int $marginModules = 2): void
    {
        if (! extension_loaded('gd')) {
            throw new RuntimeException('GD is required to generate QR images.');
        }

        $qrCode = Encoder::encode($content, ErrorCorrectionLevel::M());
        $matrix = $qrCode->getMatrix();
        $modules = $matrix->getWidth();
        $totalModules = $modules + ($marginModules * 2);
        $modulePx = max(1, (int) floor($pixelSize / $totalModules));
        $imageSize = $modulePx * $totalModules;

        $image = \imagecreatetruecolor($imageSize, $imageSize);
        if ($image === false) {
            throw new RuntimeException('Could not create QR image.');
        }

        $white = \imagecolorallocate($image, 255, 255, 255);
        $black = \imagecolorallocate($image, 30, 41, 59);
        \imagefilledrectangle($image, 0, 0, $imageSize, $imageSize, $white);

        for ($y = 0; $y < $modules; $y++) {
            for ($x = 0; $x < $modules; $x++) {
                if ($matrix->get($x, $y) === 0) {
                    continue;
                }

                $x1 = ($x + $marginModules) * $modulePx;
                $y1 = ($y + $marginModules) * $modulePx;
                \imagefilledrectangle(
                    $image,
                    $x1,
                    $y1,
                    $x1 + $modulePx - 1,
                    $y1 + $modulePx - 1,
                    $black,
                );
            }
        }

        $dir = dirname($absolutePath);
        if (! is_dir($dir)) {
            mkdir($dir, 0755, true);
        }

        if (! \imagepng($image, $absolutePath)) {
            \imagedestroy($image);
            throw new RuntimeException('Could not save QR image.');
        }

        \imagedestroy($image);
    }
}
