<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Series extends Model
{
    protected $fillable = ['name','imdb_id','year'];
    protected $table = 'series';
}
