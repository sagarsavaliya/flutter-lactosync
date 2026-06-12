<?php

namespace Tests\Unit;

use App\Support\ContainerTypeMetadata;
use PHPUnit\Framework\TestCase;

class ContainerTypeMetadataTest extends TestCase
{
    public function test_resolves_custom_plastic_three_litre_from_kind_and_size(): void
    {
        $meta = ContainerTypeMetadata::resolve(
            ContainerTypeMetadata::buildName('plastic_bag', '3L'),
            'plastic_bag',
            '3L',
        );

        $this->assertSame('Plastic Bag 3L', $meta['name']);
        $this->assertSame('plastic_bag', $meta['kind']);
        $this->assertSame(3000, $meta['size_ml']);
        $this->assertSame('3L', $meta['size_key']);
    }

    public function test_resolves_glass_size_from_name_only(): void
    {
        $meta = ContainerTypeMetadata::resolve('Glass Bottle 500ml');

        $this->assertSame('glass_bottle', $meta['kind']);
        $this->assertSame(500, $meta['size_ml']);
        $this->assertSame('500ml', $meta['size_key']);
    }
}
