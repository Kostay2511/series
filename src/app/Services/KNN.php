<?php


namespace App\Services;


class KNN
{
    public static function similarity(array $params, array $paramsSeries)
    {
        $countSeries = 0;
        $currentUser = $paramsSeries[0][0];
        foreach($paramsSeries as $user) {
            if ($currentUser!=$user[0]) {
                $currentUser=$user[0];
                $countSeries = 0;
            }
            if (in_array($user[1],$params)){
                $countSeries++;
            }
        }
        return 1;
    }
}
