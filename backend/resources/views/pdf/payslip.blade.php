<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <title>Slip Gaji - {{ $employee->user->name ?? 'Karyawan' }} - {{ $period->name }}</title>
    <style>
        body {
            font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;
            font-size: 12px;
            color: #0F172A;
            line-height: 1.4;
            margin: 0;
            padding: 20px;
        }
        .header {
            border-bottom: 2px solid #0284C7;
            padding-bottom: 12px;
            margin-bottom: 16px;
        }
        .company-name {
            font-size: 18px;
            font-weight: bold;
            color: #0F172A;
            margin: 0;
        }
        .doc-title {
            font-size: 14px;
            font-weight: bold;
            color: #0284C7;
            text-transform: uppercase;
            margin-top: 4px;
        }
        .info-table {
            width: 100%;
            margin-bottom: 16px;
            border-collapse: collapse;
        }
        .info-table td {
            padding: 4px 0;
            vertical-align: top;
        }
        .info-label {
            color: #475569;
            width: 130px;
        }
        .info-colon {
            width: 15px;
            color: #475569;
        }
        .info-value {
            font-weight: 600;
        }
        .salary-table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
        }
        .salary-table th {
            background-color: #F8FAFC;
            color: #0F172A;
            text-align: left;
            padding: 8px 10px;
            border-top: 1px solid #CBD5E1;
            border-bottom: 1px solid #CBD5E1;
            font-size: 11px;
            text-transform: uppercase;
        }
        .salary-table td {
            padding: 8px 10px;
            border-bottom: 1px solid #F1F5F9;
        }
        .text-right {
            text-align: right;
        }
        .subtotal-row td {
            font-weight: bold;
            background-color: #F8FAFC;
            border-top: 1px solid #CBD5E1;
            border-bottom: 1px solid #CBD5E1;
        }
        .net-pay-box {
            background-color: #F0FDF4;
            border: 1px solid #BBF7D0;
            padding: 12px 16px;
            margin-bottom: 24px;
            border-radius: 4px;
        }
        .net-pay-label {
            font-size: 12px;
            font-weight: bold;
            color: #166534;
            text-transform: uppercase;
        }
        .net-pay-amount {
            font-size: 18px;
            font-weight: bold;
            color: #15803D;
            float: right;
        }
        .footer-signatures {
            width: 100%;
            margin-top: 30px;
            border-collapse: collapse;
        }
        .footer-signatures td {
            width: 50%;
            text-align: center;
            vertical-align: top;
        }
        .sign-space {
            height: 60px;
        }
        .sign-name {
            font-weight: bold;
            border-top: 1px solid #CBD5E1;
            display: inline-block;
            padding-top: 4px;
            min-width: 160px;
        }
        .confidential-notice {
            margin-top: 24px;
            font-size: 10px;
            color: #94A3B8;
            text-align: center;
            font-style: italic;
        }
    </style>
</head>
<body>
    <div class="header">
        <table style="width: 100%;">
            <tr>
                <td>
                    <div class="company-name">{{ $company->name ?? 'Perusahaan' }}</div>
                    <div style="color: #475569; font-size: 11px;">Sistem Informasi Manajemen SDM & Penggajian</div>
                </td>
                <td style="text-align: right;">
                    <div class="doc-title">Slip Gaji Karyawan</div>
                    <div style="color: #475569; font-size: 11px;">Periode: {{ $period->name }}</div>
                </td>
            </tr>
        </table>
    </div>

    <table class="info-table">
        <tr>
            <td class="info-label">NIK</td>
            <td class="info-colon">:</td>
            <td class="info-value">{{ $employee->nik ?? '-' }}</td>
            <td class="info-label">Departemen</td>
            <td class="info-colon">:</td>
            <td class="info-value">{{ $employee->department->name ?? '-' }}</td>
        </tr>
        <tr>
            <td class="info-label">Nama Karyawan</td>
            <td class="info-colon">:</td>
            <td class="info-value">{{ $employee->user->name ?? '-' }}</td>
            <td class="info-label">Jabatan</td>
            <td class="info-colon">:</td>
            <td class="info-value">{{ $employee->jobPosition->name ?? '-' }}</td>
        </tr>
        <tr>
            <td class="info-label">Status Hubungan Kerja</td>
            <td class="info-colon">:</td>
            <td class="info-value">{{ ucfirst($employee->employment_status ?? 'Tetap') }}</td>
            <td class="info-label">Tanggal Bayar</td>
            <td class="info-colon">:</td>
            <td class="info-value">{{ \Carbon\Carbon::parse($period->payment_date)->isoFormat('D MMMM Y') }}</td>
        </tr>
    </table>

    <table class="salary-table">
        <thead>
            <tr>
                <th style="width: 50%;">Penghasilan (Earnings)</th>
                <th class="text-right" style="width: 50%;">Jumlah (Rp)</th>
            </tr>
        </thead>
        <tbody>
            <tr>
                <td>Gaji Pokok</td>
                <td class="text-right">{{ number_format($slip->basic_salary, 0, ',', '.') }}</td>
            </tr>
            <tr>
                <td>Tunjangan Tetap</td>
                <td class="text-right">{{ number_format($slip->allowance_fixed, 0, ',', '.') }}</td>
            </tr>
            @if($slip->overtime_pay > 0)
            <tr>
                <td>Upah Lembur</td>
                <td class="text-right">{{ number_format($slip->overtime_pay, 0, ',', '.') }}</td>
            </tr>
            @endif
            <tr class="subtotal-row">
                <td>Total Penghasilan Kotor</td>
                <td class="text-right">{{ number_format($slip->basic_salary + $slip->allowance_fixed + $slip->overtime_pay, 0, ',', '.') }}</td>
            </tr>
        </tbody>
    </table>

    <table class="salary-table">
        <thead>
            <tr>
                <th style="width: 50%;">Potongan (Deductions)</th>
                <th class="text-right" style="width: 50%;">Jumlah (Rp)</th>
            </tr>
        </thead>
        <tbody>
            <tr>
                <td>Potongan Keterlambatan Absensi</td>
                <td class="text-right">{{ number_format($slip->deduction_late, 0, ',', '.') }}</td>
            </tr>
            <tr>
                <td>Potongan Ketidakhadiran (Alpha)</td>
                <td class="text-right">{{ number_format($slip->deduction_absence, 0, ',', '.') }}</td>
            </tr>
            @if($slip->deduction_other > 0)
            <tr>
                <td>Potongan Lain</td>
                <td class="text-right">{{ number_format($slip->deduction_other, 0, ',', '.') }}</td>
            </tr>
            @endif
            <tr class="subtotal-row">
                <td>Total Potongan</td>
                <td class="text-right">{{ number_format($slip->deduction_late + $slip->deduction_absence + $slip->deduction_other, 0, ',', '.') }}</td>
            </tr>
        </tbody>
    </table>

    <div class="net-pay-box">
        <span class="net-pay-label">Total Gaji Bersih (Take Home Pay)</span>
        <span class="net-pay-amount">Rp {{ number_format($slip->net_salary, 0, ',', '.') }}</span>
        <div style="clear: both;"></div>
    </div>

    <table class="footer-signatures">
        <tr>
            <td>
                <div>Disiapkan Oleh,</div>
                <div style="font-weight: 600; color: #475569;">HR & Finance</div>
                <div class="sign-space"></div>
                <div class="sign-name">{{ $company->name ?? 'Manajemen' }}</div>
            </td>
            <td>
                <div>Diterima Oleh,</div>
                <div style="font-weight: 600; color: #475569;">Karyawan Bersangkutan</div>
                <div class="sign-space"></div>
                <div class="sign-name">{{ $employee->user->name ?? 'Karyawan' }}</div>
            </td>
        </tr>
    </table>

    <div class="confidential-notice">
        Dokumen ini dibuat otomatis oleh sistem SAAS HRIS dan bersifat rahasia (confidential).
    </div>
</body>
</html>
