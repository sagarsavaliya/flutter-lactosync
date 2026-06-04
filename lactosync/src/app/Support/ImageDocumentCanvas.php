<?php

namespace App\Support;

use GdImage;
use RuntimeException;

final class ImageDocumentCanvas
{
    private GdImage $image;

    private int $width;

    private int $height;

    /** @var array{white:int, ink:int, muted:int, primary:int, danger:int, border:int, headerBg:int, grayRow:int} */
    private array $colors;

    private string $fontRegular;

    private string $fontBold;

    public function __construct(int $width, int $height)
    {
        if (! extension_loaded('gd')) {
            throw new RuntimeException('Image generation is not available on the server.');
        }

        if (! function_exists('imagettftext')) {
            throw new RuntimeException('Server GD extension is missing FreeType support for document fonts.');
        }

        $this->width = $width;
        $this->height = $height;
        $image = \imagecreatetruecolor($width, $height);
        if ($image === false) {
            throw new RuntimeException('Could not create image.');
        }

        $this->image = $image;
        [$this->fontRegular, $this->fontBold] = $this->resolveFonts();

        $this->colors = [
            'white' => \imagecolorallocate($image, 255, 255, 255),
            'ink' => \imagecolorallocate($image, 30, 41, 59),
            'muted' => \imagecolorallocate($image, 100, 116, 139),
            'primary' => \imagecolorallocate($image, 22, 163, 74),
            'danger' => \imagecolorallocate($image, 220, 38, 38),
            'border' => \imagecolorallocate($image, 226, 232, 240),
            'headerBg' => \imagecolorallocate($image, 236, 253, 245),
            'grayRow' => \imagecolorallocate($image, 245, 247, 250),
        ];

        $this->fill('white');
    }

    public function color(string $name): int
    {
        return $this->colors[$name] ?? $this->colors['ink'];
    }

    public function fill(string $colorName): void
    {
        \imagefilledrectangle($this->image, 0, 0, $this->width, $this->height, $this->color($colorName));
    }

    public function drawFilledRect(int $x1, int $y1, int $x2, int $y2, string $colorName): void
    {
        \imagefilledrectangle($this->image, $x1, $y1, $x2, $y2, $this->color($colorName));
    }

    public function drawLine(int $x1, int $y1, int $x2, int $y2, string $colorName): void
    {
        \imageline($this->image, $x1, $y1, $x2, $y2, $this->color($colorName));
    }

    public function drawRect(int $x1, int $y1, int $x2, int $y2, string $colorName): void
    {
        \imagerectangle($this->image, $x1, $y1, $x2, $y2, $this->color($colorName));
    }

    public function textWidth(string $text, int $size, bool $bold = false): int
    {
        $box = \imagettfbbox($size, 0, $bold ? $this->fontBold : $this->fontRegular, $text);
        if ($box === false) {
            return 0;
        }

        return (int) abs($box[2] - $box[0]);
    }

    public function textHeight(int $size): int
    {
        return (int) round($size * 1.35);
    }

    public function drawText(
        string $text,
        int $x,
        int $y,
        int $size,
        string $colorName,
        bool $bold = false,
        string $align = 'left',
        ?int $boxWidth = null,
    ): void {
        $text = $this->sanitize($text);
        if ($text === '') {
            return;
        }

        $font = $bold ? $this->fontBold : $this->fontRegular;
        $color = $this->color($colorName);
        $box = \imagettfbbox($size, 0, $font, $text);
        if ($box === false) {
            return;
        }

        $textWidth = abs($box[2] - $box[0]);
        $textHeight = abs($box[7] - $box[1]);

        $drawX = match ($align) {
            'center' => $x + (int) ((($boxWidth ?? $textWidth) - $textWidth) / 2),
            'right' => $x + (($boxWidth ?? $textWidth) - $textWidth),
            default => $x,
        };

        $drawY = $y + $textHeight;

        \imagettftext($this->image, $size, 0, $drawX, $drawY, $color, $font, $text);
    }

    /**
     * @return list<string>
     */
    public function wrapText(string $text, int $maxWidth, int $size, bool $bold = false): array
    {
        $text = $this->sanitize($text);
        $words = preg_split('/\s+/', $text) ?: [];
        $lines = [];
        $current = '';

        foreach ($words as $word) {
            $candidate = $current === '' ? $word : "{$current} {$word}";
            if ($this->textWidth($candidate, $size, $bold) <= $maxWidth) {
                $current = $candidate;
            } else {
                if ($current !== '') {
                    $lines[] = $current;
                }
                $current = $word;
            }
        }

        if ($current !== '') {
            $lines[] = $current;
        }

        return $lines === [] ? [''] : $lines;
    }

    public function drawPngImage(string $absolutePath, int $x, int $y, int $maxWidth, int $maxHeight): void
    {
        if (! is_readable($absolutePath)) {
            return;
        }

        $source = \imagecreatefrompng($absolutePath);
        if ($source === false) {
            return;
        }

        $srcW = \imagesx($source);
        $srcH = \imagesy($source);
        if ($srcW <= 0 || $srcH <= 0) {
            \imagedestroy($source);

            return;
        }

        $scale = min($maxWidth / $srcW, $maxHeight / $srcH, 1.0);
        $destW = max(1, (int) round($srcW * $scale));
        $destH = max(1, (int) round($srcH * $scale));

        \imagecopyresampled(
            $this->image,
            $source,
            $x,
            $y,
            0,
            0,
            $destW,
            $destH,
            $srcW,
            $srcH,
        );

        \imagedestroy($source);
    }

    public function savePng(string $absolutePath): void
    {
        $dir = dirname($absolutePath);
        if (! is_dir($dir)) {
            mkdir($dir, 0755, true);
        }

        if (! \imagepng($this->image, $absolutePath)) {
            throw new RuntimeException('Could not save image.');
        }

        \imagedestroy($this->image);
    }

    private function sanitize(string $text): string
    {
        $text = str_replace(["\u{2013}", "\u{2014}", '·'], ['-', '-', '-'], $text);
        $text = preg_replace('/[^\P{L}\P{N}\s.,()\-\/:@#&+]/u', '', $text) ?? $text;

        return trim($text);
    }

    /**
     * @return array{0: string, 1: string}
     */
    private function resolveFonts(): array
    {
        $regular = '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf';
        $bold = '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf';

        foreach ([$regular, $bold] as $path) {
            if (! is_readable($path)) {
                throw new RuntimeException('Document font missing on server. Install fonts-dejavu-core.');
            }
        }

        return [$regular, $bold];
    }
}
