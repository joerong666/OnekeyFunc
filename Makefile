FUNC_DIR = ucmha
SSL_DIR = openssl
BINVERSION = $(shell egrep '^BINVERSION=' ../configure.ac |awk -F'=' '{print $$2}')
DIST_PACKAGE = ucmha-func-$(BINVERSION).tar.bz2
FUNC_HOME = $(HOME)/local/$(FUNC_DIR)
SSL_HOME = $(HOME)/local/$(SSL_DIR)

.PHONY: default func-inst func-clean func-dist

default:
	@echo "Available targets to make: func-inst, func-clean, func-dist, all"

func-inst:
	cd tool &&  ./func_install_new.sh $(FUNC_HOME)

func-clean:
	rm -rf $(SSL_HOME)
	rm -rf $(FUNC_HOME) 

func-dist:
	@if [ -d $(FUNC_DIR) -o -d $(SSL_DIR) ]; \
	then \
	echo "Copy failed, directory $(FUNC_DIR) or $(SSL_DIR) has existed"; \
	exit 1; \
	fi

	cp tool/func_mgr.sh $(FUNC_HOME)/bin
	cp tool/quick_*.sh $(FUNC_HOME)/bin
	chmod +x $(FUNC_HOME)/bin/*.sh
	mkdir -p $(FUNC_HOME)/bin/script
	cp tool/func/*.sh $(FUNC_HOME)/bin/script
	cp ../umysql/umysql $(FUNC_HOME)/bin/script
	chmod +x $(FUNC_HOME)/bin/script/*
	cp -r $(FUNC_HOME) .
	tar -jcf  $(DIST_PACKAGE) $(FUNC_DIR)
	rm -rf $(FUNC_DIR)
	
all: func-inst func-dist
