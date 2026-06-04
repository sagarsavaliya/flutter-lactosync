<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <style>
        body { font-family: DejaVu Sans Mono, monospace; font-size: 10px; color: #222; margin: 16px; }
        .title { text-align: center; font-size: 13px; font-weight: bold; margin-bottom: 10px; }
        .meta { margin-bottom: 8px; }
        table { width: 100%; border-collapse: collapse; }
        th, td { border: 1px solid #999; padding: 4px; text-align: center; }
        th { background: #f0f0f0; }
        td.date { text-align: left; }
    </style>
</head>
<body>
    <div class="title">MILK DELIVERY LOG</div>
    <div class="meta"><strong>{{ $customerName }}</strong> · {{ $billingMonth }}</div>
    <div class="meta">{{ $farmName }}</div>

    <table>
        <thead>
            <tr>
                <th class="date">Date</th>
                <th>Morning</th>
                <th>Evening</th>
                <th>Products</th>
            </tr>
        </thead>
        <tbody>
            @forelse($rows as $row)
                <tr>
                    <td class="date">{{ $row['date'] }}</td>
                    <td>{{ $row['morning'] ?? '—' }}</td>
                    <td>{{ $row['evening'] ?? '—' }}</td>
                    <td style="font-size:9px;">{{ $row['products'] }}</td>
                </tr>
            @empty
                <tr><td colspan="4">No deliveries recorded for this month.</td></tr>
            @endforelse
        </tbody>
    </table>
</body>
</html>
