<?php

namespace App\Console\Commands;

use App\Models\Series;
use App\Models\UserRating;
use DiDom\Document;
use GuzzleHttp\Promise;
use GuzzleHttp\Client;
use GuzzleHttp\Pool;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;

class CheckSeriesKNNCommand extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'parse';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Command description';

    /**
     * Create a new command instance.
     *
     * @return void
     */
    public function __construct()
    {
        parent::__construct();
    }

    /**
     * Execute the console command.
     *
     * @return mixed
     */
    public function handle()
    {
        $countRequest = 1000;
        $clientId = 1005183;
        Cache::forget('proxy');
        Cache::forget('failedUsers');

        $client = new Client();
        $requests = $this->createRequest($client);
        $pool = $this->createNewPool($client, $requests, $clientId, $countRequest);
        $promise = $pool->promise();
        $promise->wait();
        $poolSecond = $this->createNewPool($client, $requests, $clientId, $countRequest);
        $promise = $poolSecond->promise();
        $promise->wait();
    }

    /**
     * @param string $proxy
     * @return string
     */
    private function getRandomProxy(): string
    {
        $arrayProxy = Cache::remember('proxy', 3600, function () {
            $proxy = Http::get('http://spys.me/proxy.txt')->body();
            $pattern = '/(?<proxy>(\d+\.){3}\d+:\d+)\s+.+\s+\+/';
            preg_match_all($pattern, $proxy, $arrayProxy);
            return $arrayProxy['proxy'];
        });
        return $arrayProxy[array_rand($arrayProxy)];
    }

    /**
     * @param $proxy
     */
    private function deleteProxy($proxy)
    {
        $arrayProxy = Cache::pull('proxy');
        unset($arrayProxy[array_search($proxy, $arrayProxy)]);
        Cache::put('proxy', $arrayProxy);
    }

    /**
     * @param string $proxy
     * @return array
     */
    private function requestParams(string $proxy)
    {
        return [
            'proxy' => $proxy,
            'headers' => [
                'accept-language' => 'ru-RU',
                'content-language' => 'ru-RU',
                'content-type' => 'text/html; charset=utf-8',
                'accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9',
                'user-agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/83.0.4103.61 Safari/537.36',
                'sec-fetch-user' => '?1',
            ]
        ];
    }

    /**
     * @param $client
     * @return \Closure
     */
    private function createRequest($client)
    {
        $requests = function ($from, $count, $failedUsers) use ($client) {
            if ($failedUsers) {
                foreach ($failedUsers as $user) {
                    $proxy = $this->getRandomProxy();
                    $this->line('sending ' . $user . ' ' . $proxy);
                    yield function () use ($client, $user, $proxy) {
                        Cache::put($user, $proxy, 3600);
                        return $client->getAsync('https://www.imdb.com/user/ur' . $user . '/reviews', $this->requestParams($proxy));
                    };
                }
            } else {
                for ($i = $from; $i < $from + $count; $i++) {
                    $proxy = $this->getRandomProxy();
                    $this->line('sending ' . $i . ' ' . $proxy);
                    yield function () use ($client, $i, $proxy) {
                        Cache::put($i, $proxy, 3600);
                        return $client->getAsync('https://www.imdb.com/user/ur' . $i . '/reviews', $this->requestParams($proxy));
                    };
                }
            }
        };
        return $requests;
    }
    /**
     *
     * @param $client
     * @param $requests
     * @param $clientId
     * @param $countRequest
     * @return Pool
     */
    private function createNewPool($client, $requests, $clientId, $countRequest)
    {
        $pool = new Pool($client, $requests($clientId, $countRequest, Cache::get('failedUsers')), [
            'concurrency' => 10,
            'fulfilled' => function ($response) use ($client) {
                $userUri = $response->getHeaders()['Entity-Id'][0];
                $pattern = '/ur(?<userId>(\d+))/';
                preg_match_all($pattern, $userUri, $userId);
                $document = new Document($response->getBody()->getContents());
                $this->getContentDocument($client, $document, $userId['userId'][0], Cache::get($userId['userId'][0]));
                $this->line('id = ' . ($userId['userId'][0]) . ' good');
                Cache::forget($userId['userId'][0]);
            },
            'rejected' => function ($reason) {
                $uri = $reason->getRequest()->getUri()->getPath();
                $pattern = '/\\/ur(?<userId>(\d+))\\//';
                preg_match_all($pattern, $uri, $userId);
                $badProxy = Cache::pull($userId['userId'][0]);
                $this->deleteProxy($badProxy);
                $this->line('id = ' . ($userId['userId'][0]) . ' ' . $reason->getMessage());
                if (!stripos($reason->getMessage(), '404 Not Found')) {
                    $failedUsers = Cache::remember('failedUsers', 3600, function () {
                        return [];
                    });
                    array_push($failedUsers, $userId['userId'][0]);
                    Cache::put('failedUsers', $failedUsers);
                }
            },
        ]);
        return $pool;
    }

    /**
     * @param $client
     * @param $document
     * @param $id
     * @param $proxy
     * @throws \DiDom\Exceptions\InvalidSelectorException
     */
    private function getContentDocument($client, $document, $id, $proxy)
    {
        $posts = $document->find('.lister-item-content');
        $loadMorBtn = $document->first('ipl-load-more ipl-load-more--loaded');
        while (!empty($loadMoreBtn)) {
            $loadMore = $document->first('.load-more-data');
            $this->line('loadmore for '.$id);
            $dataKey = $loadMore->getAttribute('data-key');
            $this->line('https://www.imdb.com/user/ur' . $id . '/reviews/_ajax?ref_=undefined&paginationKey=' . $dataKey);
            $response = $client
                ->requestAsync('https://www.imdb.com/user/ur' . $id . '/reviews/_ajax?ref_=undefined&paginationKey=' . $dataKey, $this->requestParams($proxy))
                ->wait();
            $document = new Document($response->getBody()->getContents());
            $otherPosts = $document->find('.lister-item-content');
            $posts = array_merge($posts, $otherPosts);
            $loadMore = $document->first('.load-more-data');
        }
        if (count($posts) > 2) {
            foreach ($posts as $post) {
                $name = $post->first('a')->text();
                $href = $post->first('a')->getAttribute('href');
                $userScale = $post->find('.rating-other-user-rating');
                if (!empty($userScale)) {
                    $scale = $userScale[0]->find('span')[1]->text();
                    $subject = $post->first('.lister-item-year.text-muted.unbold');
                    $pattern = '/\d{4}/';
                    preg_match($pattern, $subject, $matches);
                    $year = $matches[0];
                    $this->line($scale . ' ' . $year . ' ' . $name);
                    $series = Series::firstOrCreate([
                        'name' => $name,
                        'imdb_id' => $href,
                        'year' => $year,
                    ]);
                    UserRating::firstOrCreate([
                        'id_series' => $series['id'],
                        'user_id' => $id,
                        'user_rating' => $scale,
                    ]);
                }
            }
        }
    }
}
