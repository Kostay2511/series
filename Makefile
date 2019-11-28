SHELL := bash
VARS := set -a && source laradock/.env && source .docker.env
COMPOSE := docker-compose -f laradock/docker-compose.yml -f docker-compose.yml

PHP_VERSION := "7.3"

#OFF_CMD := "sed -i 's/^zend_extension=/;zend_extension=/g' /usr/local/etc/php7.3/conf.d/docker-php-ext-xdebug.ini"
#ON_CMD= "sed -i 's/^;zend_extension=/zend_extension=/g' /usr/local/etc/php7.3/conf.d/docker-php-ext-xdebug.ini"

help:
	@echo "help is here"

up-workspace:
	@$(VARS) && $(COMPOSE) up -d workspace-ex

build-workspace:
	@$(VARS) && $(COMPOSE) build workspace workspace-ex || $(COMPOSE) build --no-cache workspace workspace-ex

laravel-install: build-workspace up-workspace
	@$(VARS) && $(COMPOSE) exec -u laradock workspace-ex bash -c "composer create-project --prefer-dist laravel/laravel /var/www/"

down:
	@$(VARS) && $(COMPOSE) down

logs-nginx:
	@$(VARS) && $(COMPOSE) logs nginx-ex

build:
	@$(VARS) && $(COMPOSE) build php-fpm php-fpm-ex || $(COMPOSE) build --no-cache php-fpm php-fpm-ex &
	@$(VARS) && $(COMPOSE) build workspace workspace-ex || $(COMPOSE) build --no-cache workspace workspace-ex &
	@$(VARS) && $(COMPOSE) build nginx nginx-ex || $(COMPOSE) build --no-cache nginx nginx-ex &

up:
	@$(VARS) && $(COMPOSE) up -d workspace-ex php-fpm-ex nginx-ex laravel-horizon-ex
	make xdebug-off

bash:
	@$(VARS) && $(COMPOSE) exec -u laradock workspace-ex bash

xdebug-on:
	@$(VARS) && $(COMPOSE) exec workspace-ex bash -c "sed -i 's/^;zend_extension=/zend_extension=/g' /etc/php/$(PHP_VERSION)/cli/conf.d/20-xdebug.ini"
	@$(VARS) && $(COMPOSE) exec php-fpm-ex bash -c "sed -i 's/^;zend_extension=/zend_extension=/g' /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini"
	@$(VARS) && $(COMPOSE) restart workspace-ex php-fpm-ex

xdebug-off:
	@$(VARS) && $(COMPOSE) exec workspace-ex bash -c "sed -i 's/^zend_extension=/;zend_extension=/g' /etc/php/$(PHP_VERSION)/cli/conf.d/20-xdebug.ini"
	@$(VARS) && $(COMPOSE) exec php-fpm-ex bash -c "sed -i 's/^zend_extension=/;zend_extension=/g' /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini"
	@$(VARS) && $(COMPOSE) restart workspace-ex php-fpm-ex

init:
	test -n "$(PROJECT_NAME)" || (echo PROJECT_NAME env is not specified && exit 1)
	rm -rf docker laradock .docker.env .docker.env.example .gitignore docker-compose.yml
#	rm -rf laradock
	git clone https://github.com/Laradock/laradock.git
	cd laradock && git checkout cb910c590e00cee77ebbf75867aae0c7d0199119
	cp laradock/env-example laradock/.env
	mkdir -p src

	echo "COMPOSE_PROJECT_NAME=$(PROJECT_NAME)" > .docker.env.example
	echo "DATA_PATH_HOST=~/.laradock/$(PROJECT_NAME)/data" >> .docker.env.example
	echo "APP_CODE_PATH_HOST=../src/" >> .docker.env.example
	echo "WORKSPACE_INSTALL_XDEBUG=true" >> .docker.env.example
	echo "PHP_FPM_INSTALL_XDEBUG=true" >> .docker.env.example
	echo "WORKSPACE_INSTALL_PRESTISSIMO=true" >> .docker.env.example
	echo "PHP_VERSION=$(PHP_VERSION)" >> .docker.env.example
	echo "NGINX_PHP_UPSTREAM_CONTAINER=php-fpm-ex" >> .docker.env.example
	echo "MACHINE_IP=192.168.161.199" >> .docker.env.example
	echo "PHP_IDE_CONFIG=serverName=$(PROJECT_NAME)" >> .docker.env.example

	cp .docker.env.example .docker.env

	echo "version: '3'" > docker-compose.yml

	echo ".idea/*" >> .gitignore
	echo "laradock/*" >> .gitignore
	echo "laradock" >> .gitignore
	echo ".docker.env" >> .gitignore

	sed -i 's/MSSQL_PASSWORD=yourStrong(!)Password/MSSQL_PASSWORD="yourStrong(!)Password"/g' laradock/.env
	sed -i 's/BLACKFIRE_CLIENT_ID=<client_id>/BLACKFIRE_CLIENT_ID="<client_id>"/g' laradock/.env
	sed -i 's/BLACKFIRE_CLIENT_TOKEN=<client_token>/BLACKFIRE_CLIENT_TOKEN="<client_token>"/g' laradock/.env
	sed -i 's/BLACKFIRE_SERVER_ID=<server_id>/BLACKFIRE_SERVER_ID="<server_id>"/g' laradock/.env
	sed -i 's/BLACKFIRE_SERVER_TOKEN=<server_token>/BLACKFIRE_SERVER_TOKEN="<server_token>"/g' laradock/.env
	sed -i 's/GITLAB_RUNNER_REGISTRATION_TOKEN=<my-registration-token>/GITLAB_RUNNER_REGISTRATION_TOKEN="<my-registration-token>"/g' laradock/.env
	sed -i 's/MAILU_RECAPTCHA_PUBLIC_KEY=<YOUR_RECAPTCHA_PUBLIC_KEY>/MAILU_RECAPTCHA_PUBLIC_KEY="<YOUR_RECAPTCHA_PUBLIC_KEY>"/g' laradock/.env
	sed -i 's/MAILU_RECAPTCHA_PRIVATE_KEY=<YOUR_RECAPTCHA_PRIVATE_KEY>/MAILU_RECAPTCHA_PRIVATE_KEY="<YOUR_RECAPTCHA_PRIVATE_KEY>"/g' laradock/.env
	sed -i 's/MAILU_WELCOME_SUBJECT=Welcome to your new email account/MAILU_WELCOME_SUBJECT="Welcome to your new email account"/g' laradock/.env
	sed -i 's/MAILU_WELCOME_BODY=Welcome to your new email account, if you can read this, then it is configured properly!/MAILU_WELCOME_BODY="Welcome to your new email account, if you can read this, then it is configured properly!"/g' laradock/.env
	sed -i 's/VARNISHD_PARAMS=-p default_ttl=3600 -p default_grace=3600/VARNISHD_PARAMS="-p default_ttl=3600 -p default_grace=3600"/g' laradock/.env
	sed -i 's/FILTERS=\["thumbor.filters.brightness", "thumbor.filters.contrast", "thumbor.filters.rgb", "thumbor.filters.round_corner", "thumbor.filters.quality", "thumbor.filters.noise", "thumbor.filters.watermark", "thumbor.filters.equalize", "thumbor.filters.fill", "thumbor.filters.sharpen", "thumbor.filters.strip_icc", "thumbor.filters.frame", "thumbor.filters.grayscale", "thumbor.filters.rotate", "thumbor.filters.format", "thumbor.filters.max_bytes", "thumbor.filters.convolution", "thumbor.filters.blur", "thumbor.filters.extract_focal", "thumbor.filters.no_upscale"\]/FILTERS="['thumbor.filters.brightness', 'thumbor.filters.contrast', 'thumbor.filters.rgb', 'thumbor.filters.round_corner', 'thumbor.filters.quality', 'thumbor.filters.noise', 'thumbor.filters.watermark', 'thumbor.filters.equalize', 'thumbor.filters.fill', 'thumbor.filters.sharpen', 'thumbor.filters.strip_icc', 'thumbor.filters.frame', 'thumbor.filters.grayscale', 'thumbor.filters.rotate', 'thumbor.filters.format', 'thumbor.filters.max_bytes', 'thumbor.filters.convolution', 'thumbor.filters.blur', 'thumbor.filters.extract_focal', 'thumbor.filters.no_upscale']"/g' laradock/.env
	sed -i 's/MAILU_AUTH_RATELIMIT=10\/minute;1000\/hour/MAILU_AUTH_RATELIMIT="10\/minute;1000\/hour"/g' laradock/.env
	sed -i 's/MAILU_SITENAME=Example Mail/MAILU_SITENAME="Example Mail"/g' laradock/.env

	git clone https://github.com/vladitot/laravel-maker.git tmp

	mv tmp/docker docker
	mv tmp/docker-compose.yml docker-compose.yml

	rm -rf tmp

	echo "FROM $(PROJECT_NAME)_workspace" | cat - docker/workspace-ex/Dockerfile > temp && mv temp docker/workspace-ex/Dockerfile
	echo "FROM $(PROJECT_NAME)_php-fpm" | cat - docker/php-fpm-ex/Dockerfile > temp && mv temp docker/php-fpm-ex/Dockerfile
	echo "FROM $(PROJECT_NAME)_nginx" | cat - docker/nginx-ex/Dockerfile > temp && mv temp docker/nginx-ex/Dockerfile

	echo "FROM $(PROJECT_NAME)_laravel-echo-server" | cat - docker/laravel-echo-server-ex/Dockerfile > temp && mv temp docker/laravel-echo-server-ex/Dockerfile




	cp laradock/php-fpm/php$(PHP_VERSION).ini docker/php-fpm-ex/php$(PHP_VERSION).ini
	cp laradock/php-fpm/xdebug.ini docker/php-fpm-ex/xdebug.ini
	cp laradock/workspace/xdebug.ini docker/workspace-ex/xdebug.ini

	sed -i 's/xdebug\.remote_connect_back/;xdebug.remote_connect_back/g' docker/workspace-ex/xdebug.ini
	sed -i 's/; xdebug\.remote_host=dockerhost/xdebug.remote_host=dockerhost_ext/g' docker/workspace-ex/xdebug.ini
	sed -i 's/xdebug\.remote_autostart=0/xdebug.remote_autostart=1/g' docker/workspace-ex/xdebug.ini
	sed -i 's/xdebug\.remote_enable=0/xdebug.remote_enable=1/g' docker/workspace-ex/xdebug.ini

	sed -i 's/xdebug\.remote_autostart=0/xdebug.remote_autostart=1/g' docker/php-fpm-ex/xdebug.ini
	sed -i 's/xdebug\.remote_enable=0/xdebug.remote_enable=1/g' docker/php-fpm-ex/xdebug.ini

