<?php
namespace App\Services;
use App\Models\Item;
use Illuminate\Support\Str;
class ItemMatchingService {
    public function for(Item $item) {
        $opposite = $item->type === 'lost' ? 'found' : 'lost';
        return Item::query()->where('type', $opposite)->whereIn('status', $opposite === 'lost' ? ['active'] : ['available'])
            ->when($item->category_id, fn ($q) => $q->where('category_id', $item->category_id))
            ->where('location', 'like', '%'.Str::before($item->location, ',').'%')
            ->whereBetween('occurred_on', [$item->occurred_on->copy()->subDays(14), $item->occurred_on->copy()->addDays(14)])
            ->latest()->limit(10)->get();
    }
}
