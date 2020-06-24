<?php


namespace App\Services;


use App\Events\ConfirmationMessageEvent;
use App\Events\SelectFilmEvent;

class VKApiService
{
    /**
     * @param array $params
     * @return array|string|null
     */
    public function typeOfMessage(array $params, $result)
    {
        switch ($params['type']) {
            case 'confirmation' :
                return event(new ConfirmationMessageEvent(), [], true);
                break;
            case 'message_new' :
                SelectFilmEvent::dispatch($params['object']['user_id'], $result);
                break;
        }
        return 'OK';
    }
}
