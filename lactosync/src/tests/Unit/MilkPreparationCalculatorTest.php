<?php

namespace Tests\Unit;

use App\Enums\ContainerType;
use App\Services\Operations\MilkPreparationCalculator;
use PHPUnit\Framework\TestCase;

class MilkPreparationCalculatorTest extends TestCase
{
    private MilkPreparationCalculator $calculator;

    protected function setUp(): void
    {
        parent::setUp();
        $this->calculator = new MilkPreparationCalculator;
    }

    public function test_glass_packs_two_and_half_litres(): void
    {
        $counts = $this->calculator->pack(2.5, ContainerType::GlassBottle);

        $this->assertSame(2, $counts['1L']);
        $this->assertSame(1, $counts['500ml']);
    }

    public function test_glass_packs_one_litre(): void
    {
        $counts = $this->calculator->pack(1.0, ContainerType::GlassBottle);

        $this->assertSame(1, $counts['1L']);
        $this->assertSame(0, $counts['500ml']);
    }

    public function test_plastic_packs_above_two_litres(): void
    {
        $counts = $this->calculator->pack(2.5, ContainerType::PlasticBag);

        $this->assertSame(1, $counts['2L']);
        $this->assertSame(0, $counts['1.5L']);
        $this->assertSame(0, $counts['1L']);
        $this->assertSame(1, $counts['500ml']);
    }

    public function test_plastic_packs_three_litres(): void
    {
        $counts = $this->calculator->pack(3.0, ContainerType::PlasticBag);

        $this->assertSame(1, $counts['2L']);
        $this->assertSame(0, $counts['1.5L']);
        $this->assertSame(1, $counts['1L']);
        $this->assertSame(0, $counts['500ml']);
    }

    public function test_zero_quantity_returns_zero_counts(): void
    {
        $counts = $this->calculator->pack(0, ContainerType::GlassBottle);

        $this->assertSame(0, $counts['1L']);
        $this->assertSame(0, $counts['500ml']);
    }

    public function test_litres_from_glass_counts(): void
    {
        $litres = $this->calculator->litresFromCounts([
            '1L' => 8,
            '500ml' => 8,
        ], ContainerType::GlassBottle);

        $this->assertSame(12.0, $litres);
    }
}
