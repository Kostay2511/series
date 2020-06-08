<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class UserRating extends Model
{
    protected $fillable = ['id_series','user_id','user_rating'];
    protected $table = 'user_ratings';
}
