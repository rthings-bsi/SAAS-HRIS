<?php

namespace Tests\Unit;

use App\Services\Attendance\GeofenceService;
use PHPUnit\Framework\TestCase;

class GeofenceServiceTest extends TestCase
{
    public function test_distance_between_same_coordinates_is_zero(): void
    {
        $lat = -6.2088;
        $lon = 106.8456;

        $distance = GeofenceService::calculateDistanceInMeters($lat, $lon, $lat, $lon);

        $this->assertEquals(0.0, $distance);
    }

    public function test_distance_calculation_is_accurate(): void
    {
        // Monumen Nasional (Monas): -6.175392, 106.827153
        // Stasiun Gambir: -6.176662, 106.830635
        // Distance is ~400 - 420 meters
        $monasLat = -6.175392;
        $monasLon = 106.827153;
        $gambirLat = -6.176662;
        $gambirLon = 106.830635;

        $distance = GeofenceService::calculateDistanceInMeters($monasLat, $monasLon, $gambirLat, $gambirLon);

        $this->assertGreaterThan(380, $distance);
        $this->assertLessThan(430, $distance);
    }
}
