<?php

namespace Database\Seeders;

/**
 * Gujarat Pincode Seeder — Sprint 6
 *
 * Full Gujarat dataset: download India Post pincode directory CSV from
 * data.gov.in and run the import command — see README.
 *
 * Source: India Post Pincode Directory (data.gov.in), accessed 2026-06-04.
 * This seeder contains representative pincodes for major Gujarat cities.
 */

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class GujPincodeSeeder extends Seeder
{
    public function run(): void
    {
        $now = now();

        $pincodes = [
            // Ahmedabad
            ['pincode' => '380001', 'city' => 'Ahmedabad GPO',         'district' => 'Ahmedabad',    'state' => 'Gujarat'],
            ['pincode' => '380006', 'city' => 'Ahmedabad Navrangpura', 'district' => 'Ahmedabad',    'state' => 'Gujarat'],
            ['pincode' => '380009', 'city' => 'Ahmedabad Ellisbridge', 'district' => 'Ahmedabad',    'state' => 'Gujarat'],
            ['pincode' => '380013', 'city' => 'Ahmedabad Vatva',       'district' => 'Ahmedabad',    'state' => 'Gujarat'],
            ['pincode' => '380015', 'city' => 'Ahmedabad Nikol',       'district' => 'Ahmedabad',    'state' => 'Gujarat'],

            // Surat
            ['pincode' => '395001', 'city' => 'Surat GPO',             'district' => 'Surat',        'state' => 'Gujarat'],
            ['pincode' => '395003', 'city' => 'Surat Nanpura',         'district' => 'Surat',        'state' => 'Gujarat'],
            ['pincode' => '395007', 'city' => 'Surat Adajan',          'district' => 'Surat',        'state' => 'Gujarat'],
            ['pincode' => '395009', 'city' => 'Surat Vesu',            'district' => 'Surat',        'state' => 'Gujarat'],

            // Vadodara
            ['pincode' => '390001', 'city' => 'Vadodara GPO',          'district' => 'Vadodara',     'state' => 'Gujarat'],
            ['pincode' => '390007', 'city' => 'Vadodara Fatehgunj',    'district' => 'Vadodara',     'state' => 'Gujarat'],
            ['pincode' => '390011', 'city' => 'Vadodara Manjalpur',    'district' => 'Vadodara',     'state' => 'Gujarat'],

            // Rajkot
            ['pincode' => '360001', 'city' => 'Rajkot GPO',            'district' => 'Rajkot',       'state' => 'Gujarat'],
            ['pincode' => '360002', 'city' => 'Rajkot Kalavad Road',   'district' => 'Rajkot',       'state' => 'Gujarat'],
            ['pincode' => '360005', 'city' => 'Rajkot Mavdi',          'district' => 'Rajkot',       'state' => 'Gujarat'],

            // Gandhinagar
            ['pincode' => '382001', 'city' => 'Gandhinagar Sector 1',  'district' => 'Gandhinagar',  'state' => 'Gujarat'],
            ['pincode' => '382010', 'city' => 'Gandhinagar Sector 10', 'district' => 'Gandhinagar',  'state' => 'Gujarat'],
            ['pincode' => '382024', 'city' => 'Gandhinagar Sector 24', 'district' => 'Gandhinagar',  'state' => 'Gujarat'],

            // Bhavnagar
            ['pincode' => '364001', 'city' => 'Bhavnagar GPO',         'district' => 'Bhavnagar',    'state' => 'Gujarat'],
            ['pincode' => '364002', 'city' => 'Bhavnagar Hari Nagar',  'district' => 'Bhavnagar',    'state' => 'Gujarat'],

            // Jamnagar
            ['pincode' => '361001', 'city' => 'Jamnagar GPO',          'district' => 'Jamnagar',     'state' => 'Gujarat'],
            ['pincode' => '361004', 'city' => 'Jamnagar Digvijay Plot','district' => 'Jamnagar',     'state' => 'Gujarat'],

            // Junagadh
            ['pincode' => '362001', 'city' => 'Junagadh GPO',          'district' => 'Junagadh',     'state' => 'Gujarat'],
            ['pincode' => '362002', 'city' => 'Junagadh Kalwa Chowk',  'district' => 'Junagadh',     'state' => 'Gujarat'],

            // Anand
            ['pincode' => '388001', 'city' => 'Anand GPO',             'district' => 'Anand',        'state' => 'Gujarat'],

            // Nadiad
            ['pincode' => '387001', 'city' => 'Nadiad GPO',            'district' => 'Kheda',        'state' => 'Gujarat'],

            // Mehsana
            ['pincode' => '384001', 'city' => 'Mehsana GPO',           'district' => 'Mehsana',      'state' => 'Gujarat'],
            ['pincode' => '384002', 'city' => 'Mehsana Highway',       'district' => 'Mehsana',      'state' => 'Gujarat'],

            // Surendranagar
            ['pincode' => '363001', 'city' => 'Surendranagar GPO',     'district' => 'Surendranagar','state' => 'Gujarat'],

            // Morbi
            ['pincode' => '363641', 'city' => 'Morbi GPO',             'district' => 'Morbi',        'state' => 'Gujarat'],

            // Bharuch
            ['pincode' => '392001', 'city' => 'Bharuch GPO',           'district' => 'Bharuch',      'state' => 'Gujarat'],

            // Ankleshwar
            ['pincode' => '393001', 'city' => 'Ankleshwar GPO',        'district' => 'Bharuch',      'state' => 'Gujarat'],

            // Navsari
            ['pincode' => '396445', 'city' => 'Navsari GPO',           'district' => 'Navsari',      'state' => 'Gujarat'],

            // Valsad
            ['pincode' => '396001', 'city' => 'Valsad GPO',            'district' => 'Valsad',       'state' => 'Gujarat'],

            // Palanpur
            ['pincode' => '385001', 'city' => 'Palanpur GPO',          'district' => 'Banaskantha',  'state' => 'Gujarat'],
        ];

        // Attach timestamps and batch insert with ignore on duplicate pincode
        $rows = array_map(fn ($row) => array_merge($row, [
            'created_at' => $now,
            'updated_at' => $now,
        ]), $pincodes);

        DB::table('pincodes')->insertOrIgnore($rows);
    }
}
