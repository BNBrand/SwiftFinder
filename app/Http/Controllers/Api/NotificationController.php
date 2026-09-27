<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
class NotificationController extends Controller
{
    public function index(Request $request) {
        $rows = $request->user()->notifications()->latest()->limit(50)->get()->map(fn($n) => [
            'id'=>$n->id,
            'type'=>$n->data['event_type'] ?? $n->type,
            'title'=>$n->data['title'] ?? 'SwiftFinder',
            'message'=>$n->data['message'] ?? '',
            'data'=>$n->data['data'] ?? [],
            'created_at'=>$n->created_at?->toISOString(),
            'read_at'=>$n->read_at?->toISOString(),
        ]);
        return $this->ok($rows, 'Notifications retrieved.');
    }
    public function markRead(Request $request, string $notification) {
        $n = $request->user()->notifications()->findOrFail($notification);
        $n->markAsRead();
        return $this->ok(null, 'Notification marked as read.');
    }
    public function markAllRead(Request $request) { $request->user()->unreadNotifications->markAsRead(); return $this->ok(null, 'Notifications marked as read.'); }
    private function ok($data,string $message){ return response()->json(['success'=>true,'message'=>$message,'data'=>$data]); }
}
