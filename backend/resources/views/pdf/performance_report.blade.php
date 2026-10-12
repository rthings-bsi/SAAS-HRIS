<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <title>Laporan Hasil Penilaian Kinerja SMART - {{ $period->name }}</title>
    <style>
        @page {
            margin: 15mm 12mm;
        }
        body {
            font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;
            font-size: 10px;
            color: #0F172A;
            line-height: 1.35;
            margin: 0;
            padding: 0;
        }
        .header {
            border-bottom: 2px solid #0F172A;
            padding-bottom: 8px;
            margin-bottom: 14px;
        }
        .company-name {
            font-size: 16px;
            font-weight: bold;
            color: #0F172A;
            margin: 0;
            text-transform: uppercase;
        }
        .doc-title {
            font-size: 13px;
            font-weight: bold;
            color: #0284C7;
            text-transform: uppercase;
            margin: 3px 0;
        }
        .doc-subtitle {
            font-size: 10px;
            color: #475569;
            margin: 0;
        }
        .meta-table {
            width: 100%;
            margin-bottom: 12px;
            border-collapse: collapse;
        }
        .meta-table td {
            padding: 2px 0;
            font-size: 10px;
        }
        .section-title {
            font-size: 11px;
            font-weight: bold;
            color: #0F172A;
            margin-top: 10px;
            margin-bottom: 6px;
            text-transform: uppercase;
            border-left: 3px solid #0284C7;
            padding-left: 6px;
        }
        .data-table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 14px;
        }
        .data-table th {
            background-color: #F1F5F9;
            color: #0F172A;
            padding: 6px 5px;
            border: 1px solid #CBD5E1;
            font-size: 9px;
            text-transform: uppercase;
            font-weight: bold;
            text-align: center;
        }
        .data-table td {
            padding: 5px;
            border: 1px solid #E2E8F0;
            font-size: 9.5px;
            vertical-align: middle;
        }
        .text-center { text-align: center; }
        .text-left { text-align: left; }
        .text-right { text-align: right; }
        .font-semibold { font-weight: 600; }
        .rank-badge {
            background-color: #0284C7;
            color: #FFFFFF;
            font-weight: bold;
            padding: 2px 6px;
            border-radius: 3px;
            display: inline-block;
        }
        .rank-top {
            background-color: #10B981;
        }
        .grade-badge {
            font-weight: bold;
            padding: 2px 5px;
            border-radius: 3px;
            display: inline-block;
        }
        .grade-sangat-baik { background-color: #DCFCE7; color: #166534; }
        .grade-baik { background-color: #E0F2FE; color: #075985; }
        .grade-cukup { background-color: #FEF9C3; color: #854D0E; }
        .grade-kurang { background-color: #FEE2E2; color: #991B1B; }

        .signatures {
            width: 100%;
            margin-top: 25px;
            border-collapse: collapse;
        }
        .signatures td {
            width: 50%;
            text-align: center;
            vertical-align: top;
            font-size: 10px;
        }
        .sign-space {
            height: 60px;
        }
        .sign-name {
            font-weight: bold;
            text-decoration: underline;
        }
    </style>
</head>
<body>
    <div class="header">
        <table style="width: 100%;">
            <tr>
                <td style="vertical-align: middle;">
                    <h1 class="company-name">Sistem Penunjang Keputusan Kinerja Karyawan</h1>
                    <div class="doc-title">Laporan Evaluasi Kinerja Metode SMART</div>
                    <p class="doc-subtitle">Simple Multi-Attribute Rating Technique - Berbasis HRIS</p>
                </td>
                <td style="text-align: right; vertical-align: middle;">
                    <div style="font-size: 9px; color: #64748B;">Tanggal Cetak:</div>
                    <div style="font-size: 10px; font-weight: bold;">{{ $generated_at }}</div>
                </td>
            </tr>
        </table>
    </div>

    <table class="meta-table">
        <tr>
            <td style="width: 120px; color: #475569;">Periode Penilaian</td>
            <td style="width: 10px;">:</td>
            <td style="font-weight: bold;">{{ $period->name }}</td>
            <td style="width: 120px; color: #475569;">Total Pegawai Dinilai</td>
            <td style="width: 10px;">:</td>
            <td style="font-weight: bold;">{{ count($evaluations) }} Orang</td>
        </tr>
        <tr>
            <td style="color: #475569;">Rentang Tanggal</td>
            <td>:</td>
            <td>{{ \Carbon\Carbon::parse($period->start_date)->translatedFormat('d M Y') }} s/d {{ \Carbon\Carbon::parse($period->end_date)->translatedFormat('d M Y') }}</td>
            <td style="color: #475569;">Status Evaluasi</td>
            <td>:</td>
            <td style="font-weight: bold; text-transform: uppercase; color: {{ $period->status === 'finalized' ? '#16A34A' : '#0284C7' }};">
                {{ $period->status }}
            </td>
        </tr>
    </table>

    <!-- Bagian 1: Matriks Kriteria & Pembobotan -->
    <div class="section-title">1. Matriks Kriteria & Pembobotan SMART</div>
    @php
        $sumWeight = $criteria->sum('weight');
    @endphp
    <table class="data-table">
        <thead>
            <tr>
                <th style="width: 35px;">Kode</th>
                <th class="text-left">Nama Kriteria</th>
                <th style="width: 60px;">Tipe</th>
                <th style="width: 70px;">Bobot Awal (W)</th>
                <th style="width: 90px;">Bobot Normal (w)</th>
                <th style="width: 60px;">C_min</th>
                <th style="width: 60px;">C_max</th>
                <th style="width: 90px;">Sumber Data</th>
            </tr>
        </thead>
        <tbody>
            @foreach($criteria as $c)
                @php
                    $wNorm = $sumWeight > 0 ? round(($c->weight / $sumWeight), 4) : 0;
                @endphp
                <tr>
                    <td class="text-center font-semibold">{{ $c->code }}</td>
                    <td>{{ $c->name }}</td>
                    <td class="text-center" style="text-transform: capitalize;">{{ $c->type }}</td>
                    <td class="text-center font-semibold">{{ number_format($c->weight, 0) }}</td>
                    <td class="text-center font-semibold">{{ number_format($wNorm, 4) }} ({{ round($wNorm * 100, 1) }}%)</td>
                    <td class="text-center">{{ number_format($c->c_min, 0) }}</td>
                    <td class="text-center">{{ number_format($c->c_max, 0) }}</td>
                    <td class="text-center">{{ $c->source_type === 'attendance' ? 'Presensi Otomatis' : 'Manual / Atasan' }}</td>
                </tr>
            @endforeach
            <tr style="background-color: #F8FAFC; font-weight: bold;">
                <td colspan="3" class="text-right">TOTAL BOBOT:</td>
                <td class="text-center">{{ number_format($sumWeight, 0) }}</td>
                <td class="text-center">1.0000 (100%)</td>
                <td colspan="3"></td>
            </tr>
        </tbody>
    </table>

    <!-- Bagian 2: Hasil Akhir Perangkingan SMART -->
    <div class="section-title">2. Hasil Perangkingan & Rekomendasi Kinerja Pegawai</div>
    <table class="data-table">
        <thead>
            <tr>
                <th style="width: 35px;">Rank</th>
                <th style="width: 65px;">NIK</th>
                <th class="text-left">Nama Karyawan</th>
                <th class="text-left" style="width: 95px;">Departemen</th>
                @foreach($criteria as $c)
                    <th style="width: 45px;">{{ $c->code }}</th>
                @endforeach
                <th style="width: 55px;">Skor V(a)</th>
                <th style="width: 75px;">Predikat</th>
                <th class="text-left" style="width: 130px;">Rekomendasi</th>
            </tr>
        </thead>
        <tbody>
            @forelse($evaluations as $index => $eval)
                @php
                    $detailsByCrit = $eval->details->keyBy('id_performance_criteria');
                    $rank = $eval->rank ?? ($index + 1);
                    $gradeClass = match($eval->grade) {
                        'Sangat Baik' => 'grade-sangat-baik',
                        'Baik' => 'grade-baik',
                        'Cukup' => 'grade-cukup',
                        default => 'grade-kurang',
                    };
                @endphp
                <tr>
                    <td class="text-center">
                        <span class="rank-badge {{ $rank <= 3 ? 'rank-top' : '' }}">
                            #{{ $rank }}
                        </span>
                    </td>
                    <td class="text-center" style="font-family: monospace;">{{ $eval->employee->nik ?? '-' }}</td>
                    <td class="font-semibold">{{ $eval->employee->user->name ?? 'Karyawan #' . $eval->id_employees }}</td>
                    <td>{{ $eval->employee->department->name ?? '-' }}</td>
                    @foreach($criteria as $c)
                        @php
                            $det = $detailsByCrit->get($c->id_performance_criteria);
                        @endphp
                        <td class="text-center">{{ $det ? number_format($det->raw_score, 1) : '-' }}</td>
                    @endforeach
                    <td class="text-center font-semibold" style="font-size: 10px; color: #0284C7;">
                        {{ $eval->final_score !== null ? number_format($eval->final_score, 2) : '-' }}
                    </td>
                    <td class="text-center">
                        @if($eval->grade)
                            <span class="grade-badge {{ $gradeClass }}">{{ $eval->grade }}</span>
                        @else
                            -
                        @endif
                    </td>
                    <td style="font-size: 8.5px;">{{ $eval->recommendation ?? '-' }}</td>
                </tr>
            @empty
                <tr>
                    <td colspan="{{ 7 + count($criteria) }}" class="text-center" style="padding: 15px; color: #64748B;">
                        Belum ada data evaluasi karyawan pada periode ini.
                    </td>
                </tr>
            @endforelse
        </tbody>
    </table>

    <!-- Lembar Tanda Tangan Pengesahan -->
    <table class="signatures">
        <tr>
            <td>
                <div>Mengetahui,</div>
                <div style="font-weight: bold;">HR & Talent Development Manager</div>
                <div class="sign-space"></div>
                <div class="sign-name">( .................................................... )</div>
                <div style="color: #64748B; font-size: 9px; margin-top: 3px;">NIP / NIK Manajer HRD</div>
            </td>
            <td>
                <div>Menyetujui,</div>
                <div style="font-weight: bold;">Direktur Utama / Pimpinan Instansi</div>
                <div class="sign-space"></div>
                <div class="sign-name">( .................................................... )</div>
                <div style="color: #64748B; font-size: 9px; margin-top: 3px;">NIP / NIK Direktur</div>
            </td>
        </tr>
    </table>
</body>
</html>
