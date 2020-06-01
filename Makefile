SHELL := bash
VARS := set -a && source laradock/.env && source src/.docker.env
LARADOCK_COMMIT := v10.0
-include src/.docker.env
COMPOSE := $(CLIENT) docker-compose -f laradock/docker-compose.yml -f docker-compose.yml
PROJECT_NAME := $(notdir $(patsubst %/,%,$(CURDIR)))

help:
	@echo "help is here"

up-workspace:
	@$(VARS) && $(COMPOSE) up -d workspace-ex

build-workspace:
	@$(VARS) && $(COMPOSE) build workspace || $(COMPOSE) build --no-cache workspace
	@$(VARS) && $(COMPOSE) build workspace-ex || $(COMPOSE) build --no-cache workspace-ex

laravel-install: build-workspace up-workspace
	rm -rf /var/www/{,.[^.]}*
	@$(VARS) && $(COMPOSE) \
    	exec -u laradock workspace-ex bash -c "rm -rf /var/www/{,.[^.]}* && composer create-project --prefer-dist laravel/laravel $(PROJECT_NAME) && \
    		mv $(PROJECT_NAME) $(PROJECT_NAME)_ && mv $(PROJECT_NAME)_/{,.[^.]}* /var/www/ && rm -rf $(PROJECT_NAME)_" || true
	@$(VARS) && $(COMPOSE) down

after-clone:
	rm -rf laradock
	git clone https://github.com/Laradock/laradock.git
	cp laradock/env-example laradock/.env
	cd laradock && git checkout $(LARADOCK_COMMIT)
	if [ ! -f ".docker.env" ]; then cp .docker.env.example .docker.env; fi

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

ifeq (build-one,$(firstword $(MAKECMDGOALS)))
  RUN_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(RUN_ARGS):;@:)
endif

build-one:
	@test -n "$(RUN_ARGS)" || (echo CONTAINERS is not specified. Use \"make build php-fpm nginx\" for example && exit 1)
	$(VARS) && $(COMPOSE) build $(RUN_ARGS)

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

	if [ ! -d "docker.example" ]; then \
		if [ -f ".docker.env.example" ]; then cp .docker.env.example .docker.env.example.old; fi; \
	fi

	if [ -f ".docker.env" ]; then cp .docker.env .docker.env.old; fi
	if [ -d "docker" ]; then cp -r docker docker.old; fi

	if [ -d "docker.example" ]; then \
		mv docker.example docker; \
	fi

	$(eval PHP_VERSION := $(if $(PHP_VERSION),$(PHP_VERSION),"7.4"))

	test -n "$(PROJECT_NAME)" || (echo PROJECT_NAME env is not specified && exit 1)
	rm -rf laradock
	git clone https://github.com/Laradock/laradock.git
	cp laradock/env-example laradock/.env
	cd laradock && git checkout $(LARADOCK_COMMIT)
	mkdir -p src

	echo "" >> .docker.env.example
	echo "" >> .docker.env.example
	echo "COMPOSE_PROJECT_NAME=$(PROJECT_NAME)" >> .docker.env.example
	echo "DATA_PATH_HOST=~/.laradock/$(PROJECT_NAME)/data" >> .docker.env.example
	echo "APP_CODE_PATH_HOST=../src/" >> .docker.env.example
	echo "WORKSPACE_INSTALL_XDEBUG=true" >> .docker.env.example
	echo "PHP_FPM_INSTALL_XDEBUG=true" >> .docker.env.example
	echo "PHP_FPM_INSTALL_INTL=false" >> .docker.env.example
	echo "PHP_FPM_INSTALL_IMAGEMAGICK=false" >> .docker.env.example
	echo "WORKSPACE_INSTALL_PRESTISSIMO=true" >> .docker.env.example
	echo "PHP_VERSION=$(PHP_VERSION)" >> .docker.env.example
	echo "NGINX_PHP_UPSTREAM_CONTAINER=php-fpm-ex" >> .docker.env.example
	echo "MACHINE_IP=192.168.161.199" >> .docker.env.example
	echo "PHP_IDE_CONFIG=serverName=$(PROJECT_NAME)" >> .docker.env.example


	if [ ! -f ".docker.env" ]; then cp .docker.env.example .docker.env; fi

	echo "FROM $(PROJECT_NAME)_workspace" | cat - docker/workspace-ex/Dockerfile > temp && mv temp docker/workspace-ex/Dockerfile
	echo "FROM $(PROJECT_NAME)_php-fpm" | cat - docker/php-fpm-ex/Dockerfile > temp && mv temp docker/php-fpm-ex/Dockerfile
	echo "FROM $(PROJECT_NAME)_nginx" | cat - docker/nginx-ex/Dockerfile > temp && mv temp docker/nginx-ex/Dockerfile

	echo "FROM $(PROJECT_NAME)_laravel-echo-server" | cat - docker/laravel-echo-server-ex/Dockerfile > temp && mv temp docker/laravel-echo-server-ex/Dockerfile

	cp laradock/php-fpm/php$(PHP_VERSION).ini docker/php-fpm-ex/php$(PHP_VERSION).ini

	cp laradock/php-fpm/xdebug.ini docker/php-fpm-ex/xdebug.ini
	cp laradock/workspace/xdebug.ini docker/workspace-ex/xdebug.ini

	rm -rf README.md


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