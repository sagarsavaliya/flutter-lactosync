<?php

namespace Tests\Unit;

use App\Services\Operations\MilkPreparationCalculator;
use PHPUnit\Framework\TestCase;

class MilkPreparationCalculatorTest extends TestCase
{
    private MilkPreparationCalculator $calc;

    protected function setUp(): void
    {
        parent::setUp();
        $this->calc = new MilkPreparationCalculator;
    }

    // -------------------------------------------------------------------------
    // sizesMapFromLiters
    // -------------------------------------------------------------------------

    public function test_sizes_map_from_liters_converts_correctly(): void
    {
        $map = $this->calc->sizesMapFromLiters([0.5, 1.0, 1.5, 2.0]);

        $this->assertSame(500, $map['500ml']);
        $this->assertSame(1000, $map['1L']);
        $this->assertSame(1500, $map['1.5L']);
        $this->assertSame(2000, $map['2L']);
    }

    // -------------------------------------------------------------------------
    // Glass Bottle (500ml, 1L) — greedy bin-pack
    // -------------------------------------------------------------------------

    public function test_glass_packs_two_and_half_litres(): void
    {
        $sizes = $this->calc->sizesMapFromLiters([0.5, 1.0]);
        $counts = $this->calc->packWithSizes(2.5, $sizes);

        $this->assertSame(2, $counts['1L']);
        $this->assertSame(1, $counts['500ml']);
    }

    public function test_glass_packs_one_litre(): void
    {
        $sizes = $this->calc->sizesMapFromLiters([0.5, 1.0]);
        $counts = $this->calc->packWithSizes(1.0, $sizes);

        $this->assertSame(1, $counts['1L']);
        $this->assertSame(0, $counts['500ml']);
    }

    public function test_glass_zero_quantity_returns_zero_counts(): void
    {
        $sizes = $this->calc->sizesMapFromLiters([0.5, 1.0]);
        $counts = $this->calc->packWithSizes(0.0, $sizes);

        $this->assertSame(0, $counts['1L']);
        $this->assertSame(0, $counts['500ml']);
    }

    // -------------------------------------------------------------------------
    // Plastic Bag (500ml, 1L, 1.5L, 2L) — greedy bin-pack
    // -------------------------------------------------------------------------

    public function test_plastic_packs_two_and_half_litres(): void
    {
        $sizes = $this->calc->sizesMapFromLiters([0.5, 1.0, 1.5, 2.0]);
        $counts = $this->calc->packWithSizes(2.5, $sizes);

        $this->assertSame(1, $counts['2L']);
        $this->assertSame(0, $counts['1.5L']);
        $this->assertSame(0, $counts['1L']);
        $this->assertSame(1, $counts['500ml']);
    }

    public function test_plastic_packs_three_litres(): void
    {
        $sizes = $this->calc->sizesMapFromLiters([0.5, 1.0, 1.5, 2.0]);
        $counts = $this->calc->packWithSizes(3.0, $sizes);

        $this->assertSame(1, $counts['2L']);
        $this->assertSame(0, $counts['1.5L']);
        $this->assertSame(1, $counts['1L']);
        $this->assertSame(0, $counts['500ml']);
    }

    public function test_plastic_packs_three_and_half_litres(): void
    {
        // 3.5L = 1×2L + 1×1.5L (not 1×2L + 1×1L + 1×500ml)
        $sizes = $this->calc->sizesMapFromLiters([0.5, 1.0, 1.5, 2.0]);
        $counts = $this->calc->packWithSizes(3.5, $sizes);

        $this->assertSame(1, $counts['2L']);
        $this->assertSame(1, $counts['1.5L']);
        $this->assertSame(0, $counts['1L']);
        $this->assertSame(0, $counts['500ml']);
    }

    // -------------------------------------------------------------------------
    // Bulk Container (4L, 5L, 6L) — greedy bin-pack
    // -------------------------------------------------------------------------

    public function test_bulk_packs_six_litres(): void
    {
        $sizes = $this->calc->sizesMapFromLiters([4.0, 5.0, 6.0]);
        $counts = $this->calc->packWithSizes(6.0, $sizes);

        $this->assertSame(0, $counts['4L']);
        $this->assertSame(0, $counts['5L']);
        $this->assertSame(1, $counts['6L']);
    }

    public function test_bulk_packs_ten_litres(): void
    {
        $sizes = $this->calc->sizesMapFromLiters([4.0, 5.0, 6.0]);
        $counts = $this->calc->packWithSizes(10.0, $sizes);

        $this->assertSame(1, $counts['6L']);
        $this->assertSame(0, $counts['5L']);
        $this->assertSame(1, $counts['4L']);
    }

    // -------------------------------------------------------------------------
    // Remainder rounds up into smallest container
    // -------------------------------------------------------------------------

    public function test_remainder_rounds_up_into_smallest(): void
    {
        // 2L with only [1L, 500ml] available — glass style
        $counts = $this->calc->packWithSizes(2.0, ['1L' => 1000, '500ml' => 500]);

        $this->assertSame(2, $counts['1L']);
        $this->assertSame(0, $counts['500ml']);
    }

    public function test_two_and_half_without_two_litre_repacks(): void
    {
        $counts = $this->calc->packWithSizes(2.5, [
            '1.5L' => 1500,
            '1L' => 1000,
            '500ml' => 500,
        ]);

        $this->assertSame(1, $counts['1.5L']);
        $this->assertSame(1, $counts['1L']);
        $this->assertSame(0, $counts['500ml']);
    }

    public function test_custom_three_litre_bag_packs_three_and_half(): void
    {
        $counts = $this->calc->packWithSizes(3.5, ['3L' => 3000, '500ml' => 500]);

        $this->assertSame(1, $counts['3L']);
        $this->assertSame(1, $counts['500ml']);
    }

    // -------------------------------------------------------------------------
    // litresFromCountsWithSizes
    // -------------------------------------------------------------------------

    public function test_litres_from_counts(): void
    {
        $sizes = $this->calc->sizesMapFromLiters([0.5, 1.0]);
        $litres = $this->calc->litresFromCountsWithSizes(['1L' => 8, '500ml' => 8], $sizes);

        $this->assertSame(12.0, $litres);
    }
}
