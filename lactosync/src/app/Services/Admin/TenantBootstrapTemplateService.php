<?php

namespace App\Services\Admin;

use PhpOffice\PhpSpreadsheet\Cell\DataValidation;
use PhpOffice\PhpSpreadsheet\Spreadsheet;
use PhpOffice\PhpSpreadsheet\Style\Alignment;
use PhpOffice\PhpSpreadsheet\Style\Fill;
use PhpOffice\PhpSpreadsheet\Writer\Xlsx;

class TenantBootstrapTemplateService
{
    public function buildBinary(): string
    {
        $spreadsheet = new Spreadsheet;
        $spreadsheet->getProperties()
            ->setCreator('LactoSync')
            ->setTitle('Tenant Bootstrap Template')
            ->setDescription('Guided workbook for super-admin day-1 dairy farm onboarding');

        $this->buildReadmeSheet($spreadsheet);
        $this->buildFarmSheet($spreadsheet);
        $this->buildProductsSheet($spreadsheet);
        $this->buildCustomersSheet($spreadsheet);
        $this->buildSubscriptionsSheet($spreadsheet);
        $this->buildRoutesSheet($spreadsheet);
        $this->buildRouteCustomersSheet($spreadsheet);
        $this->buildValidValuesSheet($spreadsheet);

        $spreadsheet->setActiveSheetIndex(0);

        $path = tempnam(sys_get_temp_dir(), 'ls-bootstrap-');
        if ($path === false) {
            throw new \RuntimeException('Unable to create temporary file for workbook export.');
        }

        try {
            (new Xlsx($spreadsheet))->save($path);
            $binary = file_get_contents($path);
            if ($binary === false) {
                throw new \RuntimeException('Unable to read generated workbook.');
            }

            return $binary;
        } finally {
            @unlink($path);
            $spreadsheet->disconnectWorksheets();
        }
    }

    private function buildReadmeSheet(Spreadsheet $spreadsheet): void
    {
        $sheet = $spreadsheet->getActiveSheet();
        $sheet->setTitle(TenantBootstrapWorkbookSpec::SHEET_README);

        $lines = [
            ['LactoSync — Tenant Day-1 Bootstrap Workbook'],
            [''],
            ['Purpose', 'Fill each sheet in order, then upload from Super Admin → Tenant → Day-1 Data Bootstrap.'],
            [''],
            ['Fill order', '1) Farm Profile  2) Products  3) Customers  4) Subscriptions  5) Routes  6) Route Customers'],
            [''],
            ['Rules'],
            ['• Do not rename sheets or column headers.'],
            ['• customer_contact must be a valid 10-digit Indian mobile number.'],
            ['• product_name and customer_contact in Subscriptions must already exist in their sheets.'],
            ['• route_name + shift in Route Customers must match a row in Routes.'],
            ['• Use the Valid Values sheet for allowed dropdown options.'],
            ['• container_type_name = packaging only (Glass Bottle / Plastic Bag). Sizes go in available_container_sizes.'],
            ['• quantity_ltr on Subscriptions = litres per shift (0.5, 1, 1.5, 2) — not the container type name.'],
            ['• Leave optional columns blank when not applicable (e.g. walk-in customers).'],
            [''],
            ['Support', 'Akshara Technologies · LactoSync Super Admin'],
        ];

        $row = 1;
        foreach ($lines as $line) {
            $sheet->setCellValue("A{$row}", $line[0] ?? '');
            if (isset($line[1])) {
                $sheet->setCellValue("B{$row}", $line[1]);
            }
            $row++;
        }

        $sheet->getStyle('A1')->getFont()->setBold(true)->setSize(14);
        $sheet->getColumnDimension('A')->setWidth(22);
        $sheet->getColumnDimension('B')->setWidth(90);
    }

    private function buildFarmSheet(Spreadsheet $spreadsheet): void
    {
        $sheet = $spreadsheet->createSheet();
        $sheet->setTitle(TenantBootstrapWorkbookSpec::SHEET_FARM);

        $headers = TenantBootstrapWorkbookSpec::farmHeaders();
        $this->writeHeaderRow($sheet, $headers);
        $sheet->fromArray([
            'Demo Dairy Farm',
            'Main Road Near Temple',
            'Rajkot',
            'Gujarat',
            '360001',
            '24ABCDE1234F1Z5',
            '1',
        ], null, 'A2');
        $sheet->freezePane('A2');
    }

    private function buildProductsSheet(Spreadsheet $spreadsheet): void
    {
        $sheet = $spreadsheet->createSheet();
        $sheet->setTitle(TenantBootstrapWorkbookSpec::SHEET_PRODUCTS);

        $headers = TenantBootstrapWorkbookSpec::productHeaders();
        $this->writeHeaderRow($sheet, $headers);
        $sheet->fromArray([
            ['Buffalo Milk', 'Buffalo', 80, 'Glass Bottle', '500ml, 1L', 1],
            ['Cow Milk', 'Cow', 65, 'Plastic Bag', '500ml, 1L, 1.5L, 2L', 1],
        ], null, 'A2');
        $sheet->freezePane('A2');
        $this->autoSizeColumns($sheet, count($headers));
    }

    private function buildCustomersSheet(Spreadsheet $spreadsheet): void
    {
        $sheet = $spreadsheet->createSheet();
        $sheet->setTitle(TenantBootstrapWorkbookSpec::SHEET_CUSTOMERS);

        $headers = TenantBootstrapWorkbookSpec::customerHeaders();
        $this->writeHeaderRow($sheet, $headers);
        $sheet->fromArray([
            [
                'Adarsh', 'Patel', '9876543210', '9876500000', 'home_delivery', 1,
                '12 Shanti Nagar', 'Adarsh City', 'Block B', 'Rajkot', 'Gujarat', '360001', 1,
            ],
            [
                'Rita', 'Shah', '9876543211', '', 'home_delivery', 1,
                '45 Ring Road', 'Shanti Nagar', 'Near Park', 'Rajkot', 'Gujarat', '360002', 1,
            ],
        ], null, 'A2');
        $sheet->freezePane('A2');
        $this->autoSizeColumns($sheet, count($headers));
    }

    private function buildSubscriptionsSheet(Spreadsheet $spreadsheet): void
    {
        $sheet = $spreadsheet->createSheet();
        $sheet->setTitle(TenantBootstrapWorkbookSpec::SHEET_SUBSCRIPTIONS);

        $headers = TenantBootstrapWorkbookSpec::subscriptionHeaders();
        $this->writeHeaderRow($sheet, $headers);
        $sheet->fromArray([
            ['9876543210', 'Buffalo Milk', 'morning', 1, 0],
            ['9876543211', 'Cow Milk', 'evening', 0.5, 2],
        ], null, 'A2');
        $sheet->freezePane('A2');
        $this->autoSizeColumns($sheet, count($headers));
    }

    private function buildRoutesSheet(Spreadsheet $spreadsheet): void
    {
        $sheet = $spreadsheet->createSheet();
        $sheet->setTitle(TenantBootstrapWorkbookSpec::SHEET_ROUTES);

        $headers = TenantBootstrapWorkbookSpec::routeHeaders();
        $this->writeHeaderRow($sheet, $headers);
        $sheet->fromArray([
            ['Route A', 'morning', 1, 1],
            ['Route B', 'evening', 2, 1],
        ], null, 'A2');
        $sheet->freezePane('A2');
        $this->autoSizeColumns($sheet, count($headers));
    }

    private function buildRouteCustomersSheet(Spreadsheet $spreadsheet): void
    {
        $sheet = $spreadsheet->createSheet();
        $sheet->setTitle(TenantBootstrapWorkbookSpec::SHEET_ROUTE_CUSTOMERS);

        $headers = TenantBootstrapWorkbookSpec::routeCustomerHeaders();
        $this->writeHeaderRow($sheet, $headers);
        $sheet->fromArray([
            ['Route A', 'morning', '9876543210', 1],
            ['Route A', 'morning', '9876543211', 2],
        ], null, 'A2');
        $sheet->freezePane('A2');
        $this->autoSizeColumns($sheet, count($headers));
    }

    private function buildValidValuesSheet(Spreadsheet $spreadsheet): void
    {
        $sheet = $spreadsheet->createSheet();
        $sheet->setTitle(TenantBootstrapWorkbookSpec::SHEET_VALID_VALUES);

        $sheet->setCellValue('A1', 'Field');
        $sheet->setCellValue('B1', 'Guidance');
        $sheet->setCellValue('D1', 'shift');
        $sheet->setCellValue('F1', 'delivery_type');
        $sheet->setCellValue('H1', 'container_type_name');
        $this->styleHeaderRow($sheet, 1, 2);
        $sheet->getStyle('D1')->applyFromArray([
            'font' => ['bold' => true, 'color' => ['rgb' => 'FFFFFF']],
            'fill' => ['fillType' => Fill::FILL_SOLID, 'startColor' => ['rgb' => '166534']],
        ]);
        $sheet->getStyle('F1')->applyFromArray([
            'font' => ['bold' => true, 'color' => ['rgb' => 'FFFFFF']],
            'fill' => ['fillType' => Fill::FILL_SOLID, 'startColor' => ['rgb' => '166534']],
        ]);
        $sheet->getStyle('H1')->applyFromArray([
            'font' => ['bold' => true, 'color' => ['rgb' => 'FFFFFF']],
            'fill' => ['fillType' => Fill::FILL_SOLID, 'startColor' => ['rgb' => '166534']],
        ]);

        $rows = [
            ['delivery_type', 'home_delivery for doorstep delivery; walk_in for counter pickup'],
            ['shift', 'morning or evening — must match between Routes and Subscriptions'],
            ['is_active / whatsapp_enabled / prefill_customer_address', '1 or 0 (yes/no also accepted on import)'],
            ['milk_type_name (examples)', 'Cow, Buffalo, Gir Cow, Kankrej Cow, Mehoni Buffalo, Jafrabadi Buffalo'],
            ['container_type_name', 'Packaging kind only — Glass Bottle, Plastic Bag, or Bulk Container (no size in name)'],
            ['available_container_sizes', 'Comma-separated sizes for that type — e.g. 500ml, 1L, 1.5L, 2L. Leave blank to use system defaults.'],
            ['quantity_ltr (Subscriptions)', 'Litres delivered per shift — must match an available size (e.g. 0.5, 1, 1.5, 2)'],
            ['coupon_amount', 'Per-litre discount in INR (0 if none)'],
        ];

        $row = 2;
        foreach ($rows as $entry) {
            $sheet->setCellValue("A{$row}", $entry[0]);
            $sheet->setCellValue("B{$row}", $entry[1]);
            $row++;
        }

        $sheet->setCellValue('D2', 'morning');
        $sheet->setCellValue('D3', 'evening');
        $sheet->setCellValue('F2', 'home_delivery');
        $sheet->setCellValue('F3', 'walk_in');
        $sheet->setCellValue('H2', 'Glass Bottle');
        $sheet->setCellValue('H3', 'Plastic Bag');
        $sheet->setCellValue('H4', 'Bulk Container');
        $sheet->setCellValue('I1', 'size_examples');
        $sheet->getStyle('I1')->applyFromArray([
            'font' => ['bold' => true, 'color' => ['rgb' => 'FFFFFF']],
            'fill' => ['fillType' => Fill::FILL_SOLID, 'startColor' => ['rgb' => '166534']],
        ]);
        $sheet->setCellValue('I2', '500ml, 1L');
        $sheet->setCellValue('I3', '500ml, 1L, 1.5L, 2L');
        $sheet->setCellValue('I4', '4L, 5L, 6L');

        $sheet->getColumnDimension('A')->setWidth(42);
        $sheet->getColumnDimension('B')->setWidth(70);

        $this->applyListValidation($spreadsheet, TenantBootstrapWorkbookSpec::SHEET_CUSTOMERS, 'E', '$F$2:$F$3');
        $this->applyListValidation($spreadsheet, TenantBootstrapWorkbookSpec::SHEET_SUBSCRIPTIONS, 'C', '$D$2:$D$3');
        $this->applyListValidation($spreadsheet, TenantBootstrapWorkbookSpec::SHEET_ROUTES, 'B', '$D$2:$D$3');
        $this->applyListValidation($spreadsheet, TenantBootstrapWorkbookSpec::SHEET_ROUTE_CUSTOMERS, 'B', '$D$2:$D$3');
        $this->applyListValidation($spreadsheet, TenantBootstrapWorkbookSpec::SHEET_PRODUCTS, 'D', '$H$2:$H$4');
    }

    /**
     * @param list<string> $headers
     */
    private function writeHeaderRow(\PhpOffice\PhpSpreadsheet\Worksheet\Worksheet $sheet, array $headers): void
    {
        $sheet->fromArray($headers, null, 'A1');
        $this->styleHeaderRow($sheet, 1, count($headers));
    }

    private function styleHeaderRow(\PhpOffice\PhpSpreadsheet\Worksheet\Worksheet $sheet, int $row, int $colCount): void
    {
        $lastCol = chr(ord('A') + $colCount - 1);
        $range = "A{$row}:{$lastCol}{$row}";
        $sheet->getStyle($range)->applyFromArray([
            'font' => ['bold' => true, 'color' => ['rgb' => 'FFFFFF']],
            'fill' => [
                'fillType' => Fill::FILL_SOLID,
                'startColor' => ['rgb' => '166534'],
            ],
            'alignment' => ['horizontal' => Alignment::HORIZONTAL_LEFT],
        ]);
    }

    private function autoSizeColumns(\PhpOffice\PhpSpreadsheet\Worksheet\Worksheet $sheet, int $colCount): void
    {
        for ($i = 0; $i < $colCount; $i++) {
            $sheet->getColumnDimension(chr(ord('A') + $i))->setAutoSize(true);
        }
    }

    private function applyListValidation(
        Spreadsheet $spreadsheet,
        string $targetSheetName,
        string $columnLetter,
        string $formulaRangeOnValidValuesSheet,
    ): void {
        $sheet = $spreadsheet->getSheetByName($targetSheetName);
        if ($sheet === null) {
            return;
        }

        for ($row = 2; $row <= 500; $row++) {
            $validation = $sheet->getCell("{$columnLetter}{$row}")->getDataValidation();
            $validation->setType(DataValidation::TYPE_LIST);
            $validation->setErrorStyle(DataValidation::STYLE_STOP);
            $validation->setAllowBlank(true);
            $validation->setShowDropDown(true);
            $validation->setFormula1("'".TenantBootstrapWorkbookSpec::SHEET_VALID_VALUES."'!{$formulaRangeOnValidValuesSheet}");
        }
    }
}
