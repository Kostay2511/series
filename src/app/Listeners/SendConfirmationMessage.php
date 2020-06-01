<?php

namespace App\Listeners;

use App\Events\ConfirmationMessageEvent;

class SendConfirmationMessage
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
     * @param ConfirmationMessageEvent $event
     * @return void
     */
    public function handle(ConfirmationMessageEvent $event)
    {
        return config('app.vk_token');
    }
}
