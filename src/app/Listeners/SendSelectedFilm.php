<?php

namespace App\Listeners;

use App\Events\SelectFilmEvent;
use App\Services\KNN;
use Illuminate\Support\Facades\Http;

class SendSelectedFilm
{
    protected $KNN;

    /**
     * Create the event listener.
     *
     * @return void
     */
    public function __construct(KNN $KNN)
    {
        $this->KNN = $KNN;
    }

    /**
     * Handle the event.
     *
     * @param SelectFilmEvent $event
     * @return void
     */
    public function handle(SelectFilmEvent $event)
    {
        // Временно 206:8,205:9,23:7,40:6
        if (preg_match("/(\d+:\d{1,2},)?(\d+:\d{1,2})/", $event->message)) {
            $chunks = array_chunk(preg_split('/(:|,)/', $event->message), 2);
            $givenData = array_combine(array_column($chunks, 0), array_column($chunks, 1));
            $nearestUsers = $this->KNN->similarity($givenData);
            $message = $this->KNN->getNearestFilms($givenData, $nearestUsers);
        } else {
            $message = $event->message;
        }
        $userId = $event->user_id;
        if (isset($userId)) {
            Http::asForm()->post('https://api.vk.com/method/messages.send?', [
                'user_id' => $userId,
                'message' => $message,
                'access_token' => config('app.vk_confirmation_token'),
                'v' => '5.107',
                'random_id' => 0,
            ]);
        }
    }
}
