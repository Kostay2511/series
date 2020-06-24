<?php

namespace App\Listeners;

use App\Events\SelectFilmEvent;
use Illuminate\Support\Facades\Http;

class SendSelectedFilm
{
    /**
     * Create the event listener.
     *
     * @return void
     */
    public function __construct()
    {
        //
    }

    /**
     * Handle the event.
     *
     * @param SelectFilmEvent $event
     * @return void
     */
    public function handle(SelectFilmEvent $event)
    {
        if (isset($event->user_id)) {
            Http::asForm()->post('https://api.vk.com/method/messages.send?', [
                'user_id' => $event->user_id,
                'message' => $event->result,
                'access_token' => config('app.vk_confirmation_token'),
                'v' => '5.107',
                'random_id' => 0,
            ]);
        }
    }
}
