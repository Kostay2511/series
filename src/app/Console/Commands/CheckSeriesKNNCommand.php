<?php

namespace App\Console\Commands;

use App\Models\Series;
use App\Models\UserRating;
use DiDom\Document;
use GuzzleHttp\Client;
use GuzzleHttp\Exception\ClientException;
use GuzzleHttp\Exception\GuzzleException;
use GuzzleHttp\Exception\ServerException;
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
        $overall = [0, 0];
        $proxy = 0;
        $goodProxy = False;
        $clientId = 4729038;
        Cache::forget('proxy');
        for ($i = $clientId; $i < $clientId + 1; $i++) {
            $this->line('i= ' . $i);
            $proxy = $this->getRandomProxy($proxy, $goodProxy);
            $client = new Client();
            try {
                $time = microtime(true);
                $response = $client->request('GET', 'https://www.imdb.com/user/ur' . $i . '/reviews', [
                    'proxy' => $proxy,
                    'accept-language' => 'ru',
                    'content-language' => 'ru',
                    'content-type' => 'text/html; charset=utf-8',
                    'headers' => [
                        'accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9',
                        'user-agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/83.0.4103.61 Safari/537.36',
                        'sec-fetch-user' => '?1',
                    ],

                ]);
                $time = (microtime(true) - $time);
                var_dump($time);
                $overall[0] += $time;
                ++$overall[1];
                $this->line('overall: ' . $overall[1] . ' ' . $overall[0] . 's.');
                $document = new Document($response->getBody()->getContents());
                $posts = $document->find('.lister-item-content');
                $loadMore = $document->first('.load-more-data');
                while (!empty($loadMore)) {
                    $dataKey = $loadMore->getAttribute('data-key');
                    $response = $client->request('GET', 'https://www.imdb.com/user/ur'. $i . '/reviews/_ajax?ref_=undefined&paginationKey='.$dataKey, [
                        'proxy' => $proxy,
                        'accept-language' => 'ru',
                        'content-language' => 'ru',
                        'content-type' => 'text/html; charset=utf-8',
                        'headers' => [
                            'accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9',
                            'user-agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/83.0.4103.61 Safari/537.36',
                            'sec-fetch-user' => '?1',
                        ],
                    ]);
                    $document = new Document($response->getBody()->getContents());
                    $otherPosts = $document->find('.lister-item-content');
                    $posts = array_merge($posts,$otherPosts);
                    $loadMore = $document->first('.load-more-data');
                }


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
                        $series = Series::firstOrCreate([
                            'name' => $name,
                            'imdb_id' => $href,
                            'year' => $year,
                        ]);
                        UserRating::firstOrCreate([
                            'id_series' => $series['id'],
                            'user_id' => $i,
                            'user_rating' => $scale,
                        ]);
                    }
                }
                $goodProxy = True;
            } catch (ClientException $e) {
                $this->line('ClientException: '.$e->getMessage());
                if ($e->getResponse()->getStatusCode() != 404) {
                    --$i;
                }
                $goodProxy = True;
            } catch (ServerException $e) {
                $this->line('ServerException: '.$e->getMessage());
                --$i;
                $goodProxy = False;
            } catch (GuzzleException $e) {
                $this->line('OtherException: '.$e->getMessage());
                --$i;
                $goodProxy = False;
            }
        }
    }

    /**
     * @param string $proxy
     * @return string
     */
    private function getRandomProxy(string $proxy, bool $goodProxy): string
    {
        Cache::remember('proxy', 3600, function () {
            $proxy = Http::get('http://spys.me/proxy.txt')->body();
            $pattern = '/(?<proxy>(\d+\.){3}\d+:\d+)\s+.+\s+\+/';
            preg_match_all($pattern, $proxy, $arrayProxy);
            return $arrayProxy['proxy'];
        });
        if ($goodProxy==False) {
            $arrayProxy = Cache::pull('proxy');
            unset($arrayProxy[array_search($proxy, $arrayProxy)]);
            Cache::put('proxy',$arrayProxy);
        }
        do {
            $currentProxyId = array_rand(Cache::get('proxy'));
            $currentProxy = Cache::get('proxy')[$currentProxyId];
        } while ($goodProxy==True and $currentProxy == $proxy);
        return $currentProxy;
    }
}
