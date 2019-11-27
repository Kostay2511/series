SHELL := bash
VARS := set -a && source laradock/.env && source .docker.env
COMPOSE := set -a && source laradock/.env && source .docker.env && docker-compose -f laradock/docker-compose.yml -f docker-compose.yml

PHP_VERSION := "7.3"

#OFF_CMD := "sed -i 's/^zend_extension=/;zend_extension=/g' /usr/local/etc/php7.3/conf.d/docker-php-ext-xdebug.ini"
#ON_CMD= "sed -i 's/^;zend_extension=/zend_extension=/g' /usr/local/etc/php7.3/conf.d/docker-php-ext-xdebug.ini"

help:
	@echo "help is here"

up-workspace:
	@$(COMPOSE) up -d workspace-ex

build-workspace:
	@$(COMPOSE) build workspace workspace-ex

install-laravel: up-workspace
	@$(COMPOSE) exec -u laradock workspace-ex bash -c "composer create-project --prefer-dist laravel/laravel /var/www/"

down:
	@$(COMPOSE) down

build:
	@$(COMPOSE) build --parallel workspace php-fpm nginx workspace-ex php-fpm-ex

up:
	@$(COMPOSE) up -d workspace-ex php-fpm-ex nginx

bash:
	@$(COMPOSE) exec -u laradock workspace-ex bash

xdebug-on:
	@$(COMPOSE) exec workspace-ex bash -c "sed -i 's/^;zend_extension=/zend_extension=/g' /etc/php/$(PHP_VERSION)/cli/conf.d/20-xdebug.ini"
	@$(COMPOSE) exec php-fpm-ex bash -c "sed -i 's/^;zend_extension=/zend_extension=/g' /usr/local/etc/php$(PHP_VERSION)/conf.d/docker-php-ext-xdebug.ini"
	@$(COMPOSE) restart workspace-ex php-fpm-ex

xdebug-off:
	@$(COMPOSE) exec workspace-ex bash -c "sed -i 's/^zend_extension=/;zend_extension=/g' /etc/php/$(PHP_VERSION)/cli/conf.d/20-xdebug.ini"
	@$(COMPOSE) exec php-fpm-ex bash -c "sed -i 's/^zend_extension=/;zend_extension=/g' /usr/local/etc/php$(PHP_VERSION)/conf.d/docker-php-ext-xdebug.ini"
	@$(COMPOSE) restart workspace-ex php-fpm-ex

init:
	test -n "$(PROJECT_NAME)" || (echo PROJECT_NAME env is not specified && exit 1)
	rm -rf docker laradock src .docker.env .docker.env.example .gitignore docker-compose.yml
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

	mkdir -p docker docker/workspace-ex docker/php-fpm-ex

	echo "FROM $(PROJECT_NAME)_workspace" > docker/workspace-ex/Dockerfile

	echo "services:" >> docker-compose.yml
	echo "  workspace-ex:" >> docker-compose.yml
	echo "    build:" >> docker-compose.yml
	echo "      context: ../docker/workspace-ex" >> docker-compose.yml
	echo "    volumes:" >> docker-compose.yml
	echo '      - $${APP_CODE_PATH_HOST}:$${APP_CODE_PATH_CONTAINER}$${APP_CODE_CONTAINER_FLAG}' >> docker-compose.yml
	echo "    environment:" >> docker-compose.yml
	echo '      - PHP_IDE_CONFIG=$${PHP_IDE_CONFIG}' >> docker-compose.yml
	echo "      - DOCKER_HOST=tcp://docker-in-docker:2375" >> docker-compose.yml
	echo "    networks:" >> docker-compose.yml
	echo "      - frontend" >> docker-compose.yml
	echo "      - backend" >> docker-compose.yml
	echo "    links:" >> docker-compose.yml
	echo "      - docker-in-docker" >> docker-compose.yml


	echo "FROM $(PROJECT_NAME)_php-fpm" > docker/php-fpm-ex/Dockerfile
	cp laradock/php-fpm/php$(PHP_VERSION).ini docker/php-fpm-ex/php$(PHP_VERSION).ini

	echo "  php-fpm-ex:" >> docker-compose.yml
	echo "    build:" >> docker-compose.yml
	echo "      context: ../docker/php-fpm-ex" >> docker-compose.yml
	echo "    volumes:" >> docker-compose.yml
	echo '      - $${APP_CODE_PATH_HOST}:$${APP_CODE_PATH_CONTAINER}$${APP_CODE_CONTAINER_FLAG}' >> docker-compose.yml
	echo "      - ../docker/php-fpm-ex/php$(PHP_VERSION).ini:/usr/local/etc/php/php.ini" >> docker-compose.yml
	echo "    environment:" >> docker-compose.yml
	echo '      - PHP_IDE_CONFIG=$${PHP_IDE_CONFIG}' >> docker-compose.yml
	echo "      - DOCKER_HOST=tcp://docker-in-docker:2375" >> docker-compose.yml
	echo '      - FAKETIME=$${PHP_FPM_FAKETIME}' >> docker-compose.yml
	echo "    networks:" >> docker-compose.yml
	echo "      - backend" >> docker-compose.yml
	echo "    links:" >> docker-compose.yml
	echo "      - docker-in-docker" >> docker-compose.yml