<?php

namespace App\Services\Attendance;

class GeofenceService
{
    /**
     * Calculate distance between two coordinates in meters using Haversine formula.
     */
    public static function calculateDistanceInMeters(float $lat1, float $lon1, float $lat2, float $lon2): float
    {
        $earthRadius = 6371000;

        $latFrom = deg2rad($lat1);
        $lonFrom = deg2rad($lon1);
        $latTo = deg2rad($lat2);
        $lonTo = deg2rad($lon2);

        $latDelta = $latTo - $latFrom;
        $lonDelta = $lonTo - $lonFrom;

        $a = sin($latDelta / 2) ** 2 +
            cos($latFrom) * cos($latTo) * (sin($lonDelta / 2) ** 2);

        $c = 2 * asin(min(1.0, sqrt($a)));

        return $c * $earthRadius;
    }
}
