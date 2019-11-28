# laravel-maker

## Painless creation of local Laradock configuration.

Laradock images inheritance included.

Ready to accept contributions.

Easy to use. Just put Makefile into empty directory, than use make init, make build, make laravel-install.

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