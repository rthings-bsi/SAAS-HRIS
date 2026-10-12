<?php

namespace Tests\Unit;

use App\Services\Performance\SmartCalculationService;
use PHPUnit\Framework\TestCase;

class SmartCalculationServiceTest extends TestCase
{
    protected SmartCalculationService $service;

    protected function setUp(): void
    {
        parent::setUp();
        $this->service = new SmartCalculationService();
    }

    public function test_grade_and_recommendation_classification(): void
    {
        [$grade1, $rec1] = $this->service->resolveGradeAndRecommendation(92.5);
        $this->assertEquals('Sangat Baik', $grade1);
        $this->assertEquals('Rekomendasi Kenaikan Gaji / Promosi', $rec1);

        [$grade2, $rec2] = $this->service->resolveGradeAndRecommendation(75.0);
        $this->assertEquals('Baik', $grade2);
        $this->assertEquals('Memenuhi Standar Perusahaan', $rec2);

        [$grade3, $rec3] = $this->service->resolveGradeAndRecommendation(62.0);
        $this->assertEquals('Cukup', $grade3);
        $this->assertEquals('Perlu Pembinaan / Monitoring', $rec3);

        [$grade4, $rec4] = $this->service->resolveGradeAndRecommendation(45.0);
        $this->assertEquals('Kurang', $grade4);
        $this->assertEquals('Diberikan Peringatan / Evaluasi Ulang', $rec4);
    }

    public function test_smart_math_benefit_and_cost_calculation(): void
    {
        // Criteria weights W: K1=40, K2=30, K3=20, K4=10. Total=100
        $sumWeight = 100.0;
        $w1 = 40.0 / $sumWeight; // 0.4
        $w2 = 30.0 / $sumWeight; // 0.3
        $w3 = 20.0 / $sumWeight; // 0.2
        $w4 = 10.0 / $sumWeight; // 0.1

        // Employee scores:
        // K1 (Benefit, Cmin=0, Cmax=100) raw=85 => u1 = ((85-0)/100)*100 = 85
        $u1 = ((85.0 - 0.0) / 100.0) * 100.0;
        $weighted1 = $w1 * $u1; // 0.4 * 85 = 34.0

        // K2 (Benefit, Cmin=0, Cmax=100) raw=90 => u2 = 90
        $u2 = ((90.0 - 0.0) / 100.0) * 100.0;
        $weighted2 = $w2 * $u2; // 0.3 * 90 = 27.0

        // K3 (Benefit, Cmin=0, Cmax=100) raw=80 => u3 = 80
        $u3 = ((80.0 - 0.0) / 100.0) * 100.0;
        $weighted3 = $w3 * $u3; // 0.2 * 80 = 16.0

        // K4 (Cost, Cmin=0, Cmax=3) raw=0 => u4 = ((3-0)/(3-0))*100 = 100
        $u4 = ((3.0 - 0.0) / (3.0 - 0.0)) * 100.0;
        $weighted4 = $w4 * $u4; // 0.1 * 100 = 10.0

        $finalScore = round($weighted1 + $weighted2 + $weighted3 + $weighted4, 2);

        $this->assertEquals(87.0, $finalScore);
        [$grade, $rec] = $this->service->resolveGradeAndRecommendation($finalScore);
        $this->assertEquals('Sangat Baik', $grade);
        $this->assertEquals('Rekomendasi Kenaikan Gaji / Promosi', $rec);
    }
}
