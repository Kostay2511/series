<?php


namespace App\Services;


use App\Events\ConfirmationMessageEvent;
use App\Events\SelectFilmEvent;

class VKApiService
{
    public function typeOfMessage(array $params)
    {
        switch ($params['type']) {
            case 'confirmation' :
                return event(new ConfirmationMessageEvent(), [], true);
                break;
            case 'message_new' :
                SelectFilmEvent::dispatch('47535111');
                break;
        }

        return 'OK';
    }
}
