<?php
namespace App\Http\Requests;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
class StoreItemRequest extends FormRequest {
    public function authorize(): bool { return true; }
    public function rules(): array { return [
        'category_id' => ['nullable','exists:categories,id'], 'type' => ['required',Rule::in(['lost','found'])],
        'title' => ['required','string','max:160'], 'description' => ['required','string','max:5000'],
        'identifying_details' => ['nullable','string','max:3000'], 'location' => ['required','string','max:255'],
        'occurred_on' => ['required','date','before_or_equal:today'], 'occurred_at' => ['nullable','date_format:H:i'],
        'contact_preference' => ['required',Rule::in(['in_app','email','whatsapp'])], 'images.*' => ['image','max:5120'],
    ]; }
}
