<?php

namespace App\Services;

use App\Models\Series;
use App\Models\UserRating;
use ErrorException;

class KNN
{
    const countKNN = 7;

    public $paramsSeries;

    public function __construct()
    {
        $this->paramsSeries = UserRating::orderBy('user_id')->get(['id_series', 'user_id', 'user_rating']);
    }

    /**
     * @param array $curUserRating
     * @param int $countNeighbors
     * @return array
     */
    public function similarity(array $curUserRating, $countNeighbors = self::countKNN)
    {
        $sumCurUserRating = 0;
        foreach ($curUserRating as $line) {
            $sumCurUserRating += pow($line, 2);
        }
        $lenCurUserRating = sqrt($sumCurUserRating);

        $simUsers = [];
        $sumSimilarRatings = $sumUserDbRating = 0;
        $currentUserId = $this->paramsSeries[0]->user_id;
        foreach ($this->paramsSeries as $line) {
            if ($currentUserId != $line->user_id) {
                if ($sumSimilarRatings) {
                    $simUsers[$currentUserId] = $sumSimilarRatings / (sqrt($sumUserDbRating) * $lenCurUserRating);
                }
                $currentUserId = $line->user_id;
                $sumSimilarRatings = $sumUserDbRating = 0;
            }
            if (array_key_exists($line->id_series, $curUserRating)) {
                $sumSimilarRatings += $line->user_rating * $curUserRating[$line->id_series];
            }
            $sumUserDbRating += pow($line->user_rating, 2);
        }

        arsort($simUsers);
        return array_slice($simUsers, 0, $countNeighbors, true);
    }

    /**
     * @param array $userRating
     * @param array $users
     * @return string
     */
    public function getNearestFilms(array $userRating, array $users)
    {
        $films = UserRating::whereIn('user_id', array_keys($users))->whereNotIn('id_series', array_keys($userRating))->get(['id_series', 'user_id', 'user_rating']);
        $topFilms = ['0' => 0, '1' => 0, '2' => 0];
        foreach ($films as $line) {
            $filmId = $line['id_series'];
            $filmTotalRating = $line['user_rating'] * $users[$line['user_id']];
            try {
                if ($topFilms[$filmId] < $filmTotalRating) {
                    $topFilms[$filmId] = $filmTotalRating;
                }
            } catch (ErrorException $exception) {
                if (min($topFilms) < $filmTotalRating) {
                    unset($topFilms[array_search(min($topFilms), $topFilms)]);
                    $topFilms[$filmId] = $filmTotalRating;
                }
            }
        }
        arsort($topFilms);
        $topFilmsNames = Series::whereIn('id', array_keys($topFilms))->get('name');
        $result = '';
        foreach ($topFilmsNames as $film) {
            $result .= $film->name . ', ';
        }
        $result = rtrim($result, ', ');
        return $result;
    }
}
