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
creates boilerplate, needed files, clones laradock repository, creates .gitignore. Base PHP version is 7.4
If you need another version, use:

`make init PHP_VERSION=7.3`

Ok. Next:

`make laravel-install` installs clean Laravel into "src" directory.

`make zero-install` installs clean Laravel-Zero into "src" directory.

`make lumen-install` installs clean Lumen into "src" directory.

`make build simple` builds containers, described at scenario "simple"

`make up simple` launch all containers, described at scenario "simple"

**simple** - is a directory at docker/config/simple. There are described, which containers need to build and start with this scenario. Scenario name is "simple". You can create your own scenarios with different containers. Just create folder and two files at docker/config/YOUR_SCENARIO_NAME.

`make down` stops all containers

`make xdebug-on` switches on debugger

`make xdebug-off` you know, what is it, isn't it? :-)

Other actions you can see in makefile. 

If you need upgrade containers, **dont put your changes to** _laradock_ directory. Put them in Dockerfiles(for example) at **./docker** directory.