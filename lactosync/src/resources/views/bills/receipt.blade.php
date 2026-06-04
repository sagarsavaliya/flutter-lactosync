<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <style>
        body { font-family: DejaVu Sans Mono, monospace; font-size: 11px; color: #222; margin: 16px; }
        .title { text-align: center; font-size: 14px; font-weight: bold; letter-spacing: 1px; margin-bottom: 12px; }
        .row { display: table; width: 100%; margin: 4px 0; }
        .label { display: table-cell; width: 45%; }
        .value { display: table-cell; text-align: right; }
        .divider { border-top: 1px dashed #888; margin: 10px 0; }
        .section-title { font-weight: bold; margin: 8px 0 4px; }
        .total { font-size: 16px; font-weight: bold; margin-top: 8px; }
        .qr-wrap { text-align: center; margin-top: 14px; }
        .qr-caption { font-size: 10px; margin-top: 6px; }
        .lines { width: 100%; border-collapse: collapse; margin-top: 6px; }
        .lines td { padding: 3px 0; border-bottom: 1px dotted #ccc; }
    </style>
</head>
<body>
    <div class="title">MILK CONSUMPTION BILL</div>

    <div class="row"><div class="label">Name</div><div class="value">{{ $customerName }}</div></div>
    <div class="row"><div class="label">Address</div><div class="value">{{ $customerAddress }}</div></div>

    <div class="divider"></div>

    <div class="section-title">Bill Details</div>
    <div class="row"><div class="label">Bill No</div><div class="value">{{ $invoiceNumber }}</div></div>
    <div class="row"><div class="label">Month</div><div class="value">{{ $billingMonth }}</div></div>
    <div class="row"><div class="label">Total Qty</div><div class="value">{{ $totalQuantity }} ltr</div></div>
    <div class="row"><div class="label">Avg Rate</div><div class="value">₹{{ number_format($averageRate, 2) }}/ltr</div></div>

    @if($lines->isNotEmpty())
        <table class="lines">
            @foreach($lines as $line)
                <tr>
                    <td>{{ $line->product_name }}</td>
                    <td style="text-align:right;">{{ $line->total_quantity }} ltr</td>
                    <td style="text-align:right;">₹{{ number_format($line->line_total, 2) }}</td>
                </tr>
            @endforeach
        </table>
    @endif

    <div class="divider"></div>

    <div class="row"><div class="label">Amount Paid</div><div class="value">₹{{ number_format($amountPaid, 2) }}</div></div>
    <div class="row total"><div class="label">Total Amount</div><div class="value">₹{{ number_format($totalAmount, 2) }}</div></div>
    <div class="row"><div class="label">Balance Due</div><div class="value">₹{{ number_format($balanceDue, 2) }}</div></div>
    <div class="row"><div class="label">Due Date</div><div class="value">{{ $dueDate }}</div></div>

    @if($qrBase64)
        <div class="qr-wrap">
            <img src="data:image/png;base64,{{ $qrBase64 }}" width="160" height="160" alt="UPI QR">
            <div class="qr-caption">Scan this QR code for UPI payment</div>
        </div>
    @endif

    <div class="divider"></div>
    <div style="text-align:center;font-size:10px;">{{ $farmName }}</div>
</body>
</html>
