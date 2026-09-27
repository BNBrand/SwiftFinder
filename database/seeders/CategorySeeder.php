<?php
namespace Database\Seeders;
use App\Models\Category;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;
class CategorySeeder extends Seeder { public function run(): void { foreach(['Phones & Electronics','Documents & IDs','Keys','Bags & Wallets','Jewelry','Pets','Clothing','Other'] as $name) Category::firstOrCreate(['slug'=>Str::slug($name)],['name'=>$name]); } }
