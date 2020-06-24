<?php

namespace App\Services;

use App\Models\Series;

class FilmService
{
    /**
     * @param array $filmsId
     * @return mixed
     */
    public function getFilmsById(array $filmsId)
    {
        return Series::whereIn('id', $filmsId)->get(['name']);
    }
}
