SHELL := bash
VARS := set -a && source laradock/.env && source .docker.env
COMPOSE := docker-compose -f laradock/docker-compose.yml -f docker-compose.yml
LARADOCK_COMMIT := v9.1
-include .docker.env
PROJECT_NAME := $(notdir $(patsubst %/,%,$(CURDIR)))

help:
	@echo "help is here"

up-workspace:
	@$(VARS) && $(COMPOSE) up -d workspace-ex

build-workspace:
	@$(VARS) && $(COMPOSE) build workspace || $(COMPOSE) build --no-cache workspace
	@$(VARS) && $(COMPOSE) build workspace-ex || $(COMPOSE) build --no-cache workspace-ex

zero-install: build-workspace up-workspace
	@$(VARS) && $(COMPOSE) \
	exec -u laradock workspace-ex bash -c "rm -rf /var/www/{,.[^.]}* && composer create-project --prefer-dist laravel-zero/laravel-zero $(PROJECT_NAME) && \
		mv $(PROJECT_NAME) $(PROJECT_NAME)_ && mv $(PROJECT_NAME)_/{,.[^.]}* /var/www/ && rm -rf $(PROJECT_NAME)_" || true
	@$(VARS) && $(COMPOSE) down

lumen-install: build-workspace up-workspace
	rm -rf /var/www/{,.[^.]}*
	@$(VARS) && $(COMPOSE) \
    	exec -u laradock workspace-ex bash -c "rm -rf /var/www/{,.[^.]}* && composer create-project --prefer-dist laravel/lumen $(PROJECT_NAME) && \
    		mv $(PROJECT_NAME) $(PROJECT_NAME)_ && mv $(PROJECT_NAME)_/{,.[^.]}* /var/www/ && rm -rf $(PROJECT_NAME)_" || true
	@$(VARS) && $(COMPOSE) down

laravel-install: build-workspace up-workspace
	rm -rf /var/www/{,.[^.]}*
	@$(VARS) && $(COMPOSE) \
    	exec -u laradock workspace-ex bash -c "rm -rf /var/www/{,.[^.]}* && composer create-project --prefer-dist laravel/laravel $(PROJECT_NAME) && \
    		mv $(PROJECT_NAME) $(PROJECT_NAME)_ && mv $(PROJECT_NAME)_/{,.[^.]}* /var/www/ && rm -rf $(PROJECT_NAME)_" || true
	@$(VARS) && $(COMPOSE) down

after-clone:
	rm -rf laradock
	git clone https://github.com/Laradock/laradock.git
	cd laradock && git checkout $(LARADOCK_COMMIT)
	cp laradock/env-example laradock/.env
	cp .docker.env.example .docker.env
	make prepare-laradock-env

composer-install:
	@$(VARS) && $(COMPOSE) run -u laradock workspace-ex bash -c "composer install"

down:
	@$(VARS) && $(COMPOSE) down

logs-nginx:
	@$(VARS) && $(COMPOSE) logs nginx-ex

logs-workspace:
	@$(VARS) && $(COMPOSE) logs workspace-ex

ifeq (rebuild,$(firstword $(MAKECMDGOALS)))
  RUN_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(RUN_ARGS):;@:)
endif

rebuild:
	@test -n "$(RUN_ARGS)" || (echo CONTAINER is not specified. Use \"make build workspace-ex\" for example && exit 1)
	$(VARS) && $(COMPOSE) build --no-cache --parallel $(RUN_ARGS)

ifeq (build,$(firstword $(MAKECMDGOALS)))
  RUN_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(RUN_ARGS):;@:)
endif

build:
	@test -n "$(RUN_ARGS)" || (echo CONTAINERS is not specified. Use \"make build simple\" for example && exit 1)

	$(eval CONTAINERS := $(subst \n, ,$(shell cat docker/config/$(RUN_ARGS)/build_common)))
	$(VARS) && $(COMPOSE) build --parallel $(CONTAINERS)

	$(eval CONTAINERS := $(subst \n, ,$(shell cat docker/config/$(RUN_ARGS)/build)))
	$(VARS) && $(COMPOSE) build --parallel $(CONTAINERS)

in:
	@$(VARS) && $(COMPOSE) exec -u laradock workspace-ex bash

xdebug-on:
	@$(VARS) && $(COMPOSE) exec workspace-ex bash -c "sed -i 's/^;zend_extension=/zend_extension=/g' /etc/php/$(PHP_VERSION)/cli/conf.d/20-xdebug.ini" || true
	@$(VARS) && $(COMPOSE) exec php-fpm-ex bash -c "sed -i 's/^;zend_extension=/zend_extension=/g' /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini" || true
	@$(VARS) && $(COMPOSE) restart workspace-ex php-fpm-ex || true

xdebug-off:
	@$(VARS) && $(COMPOSE) exec workspace-ex bash -c "sed -i 's/^zend_extension=/;zend_extension=/g' /etc/php/$(PHP_VERSION)/cli/conf.d/20-xdebug.ini" || true
	@$(VARS) && $(COMPOSE) exec php-fpm-ex bash -c "sed -i 's/^zend_extension=/;zend_extension=/g' /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini" || true
	@$(VARS) && $(COMPOSE) restart workspace-ex php-fpm-ex || true

init:
	if [ -d "docker.old" ]; then \
        echo "Check existing docker.old. Remove it. Dont loose it."; exit 1; \
    fi

	if [ -f ".docker.env.example.old" ]; then \
		echo "Check existing .docker.env.example.old. Remove it. Dont loose it."; exit 1; \
	fi

	if [ -f ".docker.env.old" ]; then \
		echo "Check existing .docker.env.old. Remove it. Dont loose it."; exit 1; \
	fi

	if [ -f ".docker.env.example" ]; then cp .docker.env.example .docker.env.example.old; fi
	if [ -f ".docker.env" ]; then cp .docker.env .docker.env.old; fi
	if [ -d "docker" ]; then cp -r docker docker.old; fi

	if [ -d "docker.example" ]; then \
		mv docker.example docker; \
	fi

	$(eval PHP_VERSION := $(if $(PHP_VERSION),$(PHP_VERSION),"7.4"))

	test -n "$(PROJECT_NAME)" || (echo PROJECT_NAME env is not specified && exit 1)
	rm -rf laradock
	git clone https://github.com/Laradock/laradock.git
	cd laradock && git checkout $(LARADOCK_COMMIT)
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

	make prepare-laradock-env

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

	rm -rf README.md

prepare-laradock-env:
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


ifeq (log,$(firstword $(MAKECMDGOALS)))
  RUN_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(RUN_ARGS):;@:)
endif

log:
	@$(VARS) && $(COMPOSE) logs $(RUN_ARGS)

ifeq (up,$(firstword $(MAKECMDGOALS)))
  RUN_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(RUN_ARGS):;@:)
endif

up:
	$(eval CONTAINERS := $(subst \n, ,$(shell cat docker/config/$(RUN_ARGS)/up)))
	@test -n "$(CONTAINERS)" || (echo CONTAINERS is not specified. Use \"make up simple\" for example && exit 1)
	@$(VARS) && $(COMPOSE) up -d $(CONTAINERS)
	make xdebug-off