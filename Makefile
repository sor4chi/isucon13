all: rotate-all app-deploy

include .env

ifeq ($(SERVER),)
    $(error SERVER env is not set)
endif

NGINX_ACCESS_LOG:=/var/log/nginx/access.ndjson
NGINX_CONF:=/etc/nginx

MYSQL_SLOW_LOG:=/var/log/mysql/mysql-slow.log
MYSQL_CONF:=/etc/mysql

APP:=/home/isucon/webapp/go
APP_BINARY:=isupipe

SERVICE:=isupipe-go.service

PPROF_EXEC_PORT:=6060
PPROF_WEBUI_PORT:=1080
PPROF_URL:=http://localhost:$(PPROF_EXEC_PORT)/debug/pprof/profile




.PHONY: rotate-all
rotate-all: rotate-access-log rotate-slow-log

.PHONY: rotate-access-log
rotate-access-log:
	echo "Rotating access log"
	if [ ! -d etc/$(SERVER)/nginx ]; then echo "nginx not configured"; exit 0; fi
	if [ ! -f $(NGINX_ACCESS_LOG) ]; then echo "access log not found"; exit 0; fi
	sudo mv $(NGINX_ACCESS_LOG) $(NGINX_ACCESS_LOG).$(shell date +%Y%m%d)
	sudo systemctl restart nginx

.PHONY: rotate-slow-log
rotate-slow-log:
	echo "Rotating slow log"
	if [ ! -d etc/$(SERVER)/mysql ]; then echo "mysql not configured"; exit 0; fi
	if [ ! -f $(MYSQL_SLOW_LOG) ]; then echo "slow log not found"; exit 0; fi
	sudo mv $(MYSQL_SLOW_LOG) $(MYSQL_SLOW_LOG).$(shell date +%Y%m%d)
	sudo systemctl restart mysql




.PHONY: alp
alp:
	echo "alp"
	alp json --config alp-config.yml

.PHONY: pt
pt:
	echo "pt-query-digest"
	sudo pt-query-digest $(MYSQL_SLOW_LOG)

.PHONY: pprof
pprof:
	echo "pprof"
	go tool pprof -seconds 60 -http=localhost:$(PPROF_WEBUI_PORT) $(PPROF_URL)




.PHONY: dump-all
dump-all: dump-nginx dump-mysql

.PHONY: dump-nginx
dump-nginx:
	echo "dump nginx conf"
	mkdir -p ./etc/$(SERVER)
	cp -r $(NGINX_CONF) ./etc/$(SERVER)

.PHONY: dump-mysql
dump-mysql:
	echo "dump nginx conf"
	mkdir -p ./etc/$(SERVER)
	cp -r $(MYSQL_CONF) ./etc/$(SERVER)




.PHONY: deploy-all
deploy-all: conf-deploy app-deploy

.PHONY: conf-deploy
conf-deploy: nginx-conf-deploy mysql-conf-deploy

.PHONY: nginx-conf-deploy
nginx-conf-deploy:
	echo "nginx conf deploy"
	if [ ! -d etc/$(SERVER)/nginx ]; then echo "nginx not configured"; exit 1; fi
	sudo cp -r etc/$(SERVER)/nginx/* $(NGINX_CONF)
	sudo nginx -t
	sudo systemctl restart nginx

.PHONY: mysql-conf-deploy
mysql-conf-deploy:
	echo "mysql conf deploy"
	if [ ! -d etc/$(SERVER)/mysql ]; then echo "mysql not configured"; exit 1; fi
	sudo cp -r etc/$(SERVER)/mysql/* $(MYSQL_CONF)
	sudo systemctl restart mysql

.PHONY: app-deploy
app-deploy:
	echo "app deploy"
	cd $(APP) && make build
	sudo systemctl restart $(SERVICE)




.PHONY: install-all
install-all: install-alp install-pt install-pprof

.PHONY: install-alp
install-alp:
	echo "install alp"
	wget
	sudo mv alp /usr/local/bin
