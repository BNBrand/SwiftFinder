<?php

use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\View;
use App\Http\Controllers\Admin\AdminController;

Route::get('/', function () {
    return view('welcome');
});

// Fallback for local environments where public/storage has not been linked yet.
// If the normal Laravel storage symlink exists, the web server serves these files directly.
Route::get('/storage/{path}', function (string $path) {
    $disk = Storage::disk('public');

    abort_unless($disk->exists($path), 404);

    return response()->file($disk->path($path));
})->where('path', '.*');


Route::get('/reset-password/{token}', function (string $token) {
    return response()->view('auth.reset-token', ['token' => $token, 'email' => request('email')]);
})->name('password.reset');

Route::prefix('admin')->name('admin.')->group(function () {
    Route::get('login',[AdminController::class,'loginForm'])->name('login');
    Route::post('login',[AdminController::class,'login'])->name('login.submit');
    Route::middleware(['auth','admin'])->group(function () {
        Route::get('/',[AdminController::class,'dashboard'])->name('dashboard');
        Route::post('logout',[AdminController::class,'logout'])->name('logout');
        Route::get('users',[AdminController::class,'users'])->name('users'); Route::patch('users/{user}/suspend',[AdminController::class,'suspend'])->name('users.suspend');
        Route::get('items',[AdminController::class,'items'])->name('items'); Route::patch('items/{item}',[AdminController::class,'updateItem'])->name('items.update');
        Route::get('claims',[AdminController::class,'claims'])->name('claims'); Route::patch('claims/{claim}',[AdminController::class,'updateClaim'])->name('claims.update'); Route::get('reports',[AdminController::class,'reports'])->name('reports'); Route::patch('reports/{report}',[AdminController::class,'resolveReport'])->name('reports.resolve');
        Route::get('categories',[AdminController::class,'categories'])->name('categories'); Route::post('categories',[AdminController::class,'saveCategory'])->name('categories.save'); Route::patch('categories/{category}',[AdminController::class,'saveCategory'])->name('categories.update');
    });
});
