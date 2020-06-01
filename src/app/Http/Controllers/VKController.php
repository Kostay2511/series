<?php

namespace App\Http\Controllers;

use App\Services\VKApiService;
use Illuminate\Http\Request;

class VKController extends Controller
{
    protected $vkApiService;

    public function __construct(VKApiService $vkApiService)
    {
        $this->vkApiService = $vkApiService;
    }

    public function getSeries(Request $request)
    {
        $content = $this->vkApiService->typeOfMessage($request->all());
        return response($content, 200)
            ->header('Content-Type', 'text/plain');
    }
}
