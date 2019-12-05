# laravel-maker

## Painless creation of local Laradock configuration.

Laradock images inheritance included.

Ready to accept contributions.

Easy to use. Just clone to your new project directory, than use make init, make build, make laravel-install.

`git clone https://github.com/vladitot/laravel-maker YOUR_PROJECT_NAME`

`cd YOUR_PROJECT_NAME`

`make init`

Enjoy!

Makefile uses https://laradock.io/

### Description

`make init`
creates boilerplate, needed files, clones laradock repository, creates .gitignore.

`make laravel-install` installs clean Laravel into "src" directory.

`make build` builds containers

`make up` launch all containers

`make down` stops all containers

`make xdebug-on` switches on debugger

`make xdebug-off` you know, what is it, isn't it? :-)

Other actions you can see in makefile. 