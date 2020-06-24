<?php

namespace App\Http\Controllers;

use App\Services\FilmService;
use App\Services\VKApiService;
use App\Services\KNN;
use Illuminate\Http\Request;

class VKController extends Controller
{
    protected $vkApiService;
    protected $KNN;
    protected $filmService;

    public function __construct(VKApiService $vkApiService, KNN $KNN,FilmService $filmService)
    {
        $this->vkApiService = $vkApiService;
        $this->KNN = $KNN;
        $this->filmService = $filmService;
    }

    /**
     * @param Request $request
     * @return \Illuminate\Contracts\Foundation\Application|\Illuminate\Contracts\Routing\ResponseFactory|\Illuminate\Http\Response
     */
    public function getSeries(Request $request)
    {
        $message = $request->all()['object']['body'];

        // Временно 206:8,205:9,23:7,40:6
        $chunks = array_chunk(preg_split('/(:|,)/', $message), 2);
        $givenData = array_combine(array_column($chunks, 0), array_column($chunks, 1));

        $nearestUsers = $this->KNN->similarity($givenData);
        $result = $this->KNN->getNearestFilms($givenData,$nearestUsers);
        $content = $this->vkApiService->typeOfMessage($request->all(),  $result);
        return response($result, 200)
            ->header('Content-Type', 'text/plain');
    }
}
