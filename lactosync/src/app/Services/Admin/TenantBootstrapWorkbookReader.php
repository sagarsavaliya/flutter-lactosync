<?php

namespace App\Services\Admin;

use Illuminate\Http\UploadedFile;
use Illuminate\Support\Str;
use PhpOffice\PhpSpreadsheet\IOFactory;
use PhpOffice\PhpSpreadsheet\Worksheet\Worksheet;

class TenantBootstrapWorkbookReader
{
    /**
     * @return array{
     *   farm_profile: array<string, string>,
     *   products: list<array<string, string>>,
     *   customers: list<array<string, string>>,
     *   subscriptions: list<array<string, string>>,
     *   routes: list<array<string, string>>,
     *   route_customers: list<array<string, string>>
     * }
     */
    public function read(UploadedFile $file): array
    {
        $spreadsheet = IOFactory::load($file->getRealPath());
        $spreadsheet->setActiveSheetIndex(0);

        $missing = [];
        foreach (TenantBootstrapWorkbookSpec::REQUIRED_SHEETS as $sheetName) {
            if ($spreadsheet->getSheetByName($sheetName) === null) {
                $missing[] = $sheetName;
            }
        }
        if ($missing !== []) {
            throw new \InvalidArgumentException(
                'Workbook is missing required sheet(s): '.implode(', ', $missing).'. Download the latest LactoSync template and try again.'
            );
        }

        return [
            'farm_profile' => $this->readSingleRowSheet(
                $spreadsheet->getSheetByName(TenantBootstrapWorkbookSpec::SHEET_FARM),
                TenantBootstrapWorkbookSpec::farmHeaders(),
            ),
            'products' => $this->readDataSheet(
                $spreadsheet->getSheetByName(TenantBootstrapWorkbookSpec::SHEET_PRODUCTS),
                TenantBootstrapWorkbookSpec::productHeaders(),
            ),
            'customers' => $this->readDataSheet(
                $spreadsheet->getSheetByName(TenantBootstrapWorkbookSpec::SHEET_CUSTOMERS),
                TenantBootstrapWorkbookSpec::customerHeaders(),
            ),
            'subscriptions' => $this->readDataSheet(
                $spreadsheet->getSheetByName(TenantBootstrapWorkbookSpec::SHEET_SUBSCRIPTIONS),
                TenantBootstrapWorkbookSpec::subscriptionHeaders(),
            ),
            'routes' => $this->readDataSheet(
                $spreadsheet->getSheetByName(TenantBootstrapWorkbookSpec::SHEET_ROUTES),
                TenantBootstrapWorkbookSpec::routeHeaders(),
            ),
            'route_customers' => $this->readDataSheet(
                $spreadsheet->getSheetByName(TenantBootstrapWorkbookSpec::SHEET_ROUTE_CUSTOMERS),
                TenantBootstrapWorkbookSpec::routeCustomerHeaders(),
            ),
        ];
    }

    /**
     * @param list<string> $headers
     * @return array<string, string>
     */
    private function readSingleRowSheet(Worksheet $sheet, array $headers): array
    {
        $rows = $this->readDataSheet($sheet, $headers);

        return $rows[0] ?? array_fill_keys($headers, '');
    }

    /**
     * @param list<string> $headers
     * @return list<array<string, string>>
     */
    private function readDataSheet(Worksheet $sheet, array $headers): array
    {
        $columnMap = $this->buildColumnMap($sheet, $headers);
        $rows = [];
        $highestRow = $sheet->getHighestDataRow();

        for ($rowIndex = 2; $rowIndex <= $highestRow; $rowIndex++) {
            $row = [];
            foreach ($headers as $header) {
                $columnLetter = $columnMap[$header];
                $value = $sheet->getCell("{$columnLetter}{$rowIndex}")->getFormattedValue();
                $row[$header] = trim((string) $value);
            }

            if ($this->isBlankRow($row)) {
                continue;
            }

            $rows[] = $row;
        }

        return $rows;
    }

    /**
     * @param list<string> $expectedHeaders
     * @return array<string, string>
     */
    private function buildColumnMap(Worksheet $sheet, array $expectedHeaders): array
    {
        $map = [];
        $highestColumn = $sheet->getHighestDataColumn();
        $highestIndex = \PhpOffice\PhpSpreadsheet\Cell\Coordinate::columnIndexFromString($highestColumn);

        for ($i = 1; $i <= $highestIndex; $i++) {
            $letter = \PhpOffice\PhpSpreadsheet\Cell\Coordinate::stringFromColumnIndex($i);
            $header = Str::lower(trim((string) $sheet->getCell("{$letter}1")->getValue()));
            if ($header !== '' && in_array($header, $expectedHeaders, true)) {
                $map[$header] = $letter;
            }
        }

        $missing = array_diff($expectedHeaders, array_keys($map));
        if ($missing !== []) {
            throw new \InvalidArgumentException(
                'Sheet "'.$sheet->getTitle().'" has invalid headers. Missing: '.implode(', ', $missing)
            );
        }

        return $map;
    }

  /**
   * @param array<string, string> $row
   */
    private function isBlankRow(array $row): bool
    {
        foreach ($row as $value) {
            if (trim($value) !== '') {
                return false;
            }
        }

        return true;
    }
}
