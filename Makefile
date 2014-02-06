TOP_DIR = ../..
include $(TOP_DIR)/tools/Makefile.common
KB_RUNTIME ?= /kb/runtime
DEPLOY_RUNTIME ?= $(KB_RUNTIME)
KB_TOP ?= /kb/deployment
TARGET ?= $(KB_TOP)
CURR_DIR = $(shell pwd)
TARGET_DIR = $(TARGET)/services/$(SERVICE_NAME)
TARGET_PORT = 7113
THREADPOOL_SIZE = 20
SERVICE_NAME = $(shell basename $(CURR_DIR))
SERVICE_SPEC = ./Inferelator.spec
SERVICE_PORT = $(TARGET_PORT)
SERVICE_DIR = $(TARGET_DIR)
SERVLET_CLASS = us.kbase.inferelator.InferelatorServer
MAIN_CLASS = us.kbase.inferelator.InferelatorInvoker
SERVICE_PSGI = $(SERVICE_NAME).psgi
TPAGE_ARGS = --define kb_top=$(TARGET) --define kb_runtime=$(DEPLOY_RUNTIME) --define kb_service_name=$(SERVICE_NAME) --define kb_service_dir=$(SERVICE_DIR) --define kb_service_port=$(SERVICE_PORT) --define kb_psgi=$(SERVICE_PSGI)
DEPLOY_JAR = $(KB_TOP)/lib/jars/inferelator
JOB_DIR = /var/tmp/inferelator
UJS_SERVICE_URL ?= https://kbase.us/services/userandjobstate
AWE_CLIENT_URL ?= http://140.221.85.171:7080/job
ID_SERVICE_URL ?= https://kbase.us/services/idserver
WS_SERVICE_URL ?= https://kbase.us/services/ws

default: compile

deploy: distrib deploy-client deploy-jar

deploy-all: distrib deploy-client

deploy-jar: compile-jar deploy-sh-scripts distrib-jar

compile-jar: src lib
	./make_jar.sh $(MAIN_CLASS)

distrib-jar:
	export KB_TOP=$(TARGET)
	rm -rf $(DEPLOY_JAR)
	mkdir -p $(DEPLOY_JAR)/lib
	cp ./lib/*.jar $(DEPLOY_JAR)/lib
	cp ./dist/inferelator.jar $(DEPLOY_JAR)

deploy-client: deploy-libs deploy-pl-scripts deploy-docs

init:
	git submodule init
	git submodule update
	mkdir -p bin
	mkdir -p classes
	echo "export PATH=$(DEPLOY_RUNTIME)/bin" > bin/compile_typespec
	echo "export PERL5LIB=$(DIR)/typecomp/lib" >> bin/compile_typespec
	echo "perl $(DIR)/typecomp/scripts/compile_typespec.pl \"\$$@\"" >> bin/compile_typespec 
	echo $(DIR) > classes/kidlinit
	chmod a+x bin/compile_typespec

deploy-libs: build-libs
	rsync --exclude '*.bak*' -arv lib/. $(TARGET)/lib/.

deploy-pl-scripts:
	export KB_TOP=$(TARGET); \
	export KB_RUNTIME=$(DEPLOY_RUNTIME); \
	export KB_PERL_PATH=$(TARGET)/lib bash ; \
	for src in $(SRC_PERL) ; do \
		basefile=`basename $$src`; \
		base=`basename $$src .pl`; \
		echo install $$src $$base ; \
		cp $$src $(TARGET)/plbin ; \
		$(WRAP_PERL_SCRIPT) "$(TARGET)/plbin/$$basefile" $(TARGET)/bin/$$base ; \
	done

deploy-docs: build-docs
	mkdir -p $(TARGET)/services/$(SERVICE_NAME)/webroot/.
	cp docs/*.html $(TARGET)/services/$(SERVICE_NAME)/webroot/.


SRC_SH = $(wildcard scripts/*.sh)
WRAP_SH_TOOL = wrap_sh
WRAP_SH_SCRIPT = bash $(TOOLS_DIR)/$(WRAP_SH_TOOL).sh

deploy-sh-scripts:
	mkdir -p $(TARGET)/shbin; \
	export KB_TOP=$(TARGET); \
	export KB_RUNTIME=$(DEPLOY_RUNTIME); \
	for src in $(SRC_SH) ; do \
		basefile=`basename $$src`; \
		base=`basename $$src .sh`; \
		echo install $$src $$base ; \
		cp $$src $(TARGET)/shbin ; \
		$(WRAP_SH_SCRIPT) "$(TARGET)/shbin/$$basefile" $(TARGET)/bin/$$base ; \
	done 

distrib:
	@echo "Target folder: $(TARGET_DIR)"
	mkdir -p $(TARGET_DIR)
	mkdir -p $(JOB_DIR)
	cp -f ./dist/service.war $(TARGET_DIR)
	cp -f ./glassfish_start_service.sh $(TARGET_DIR)
	cp -f ./glassfish_stop_service.sh $(TARGET_DIR)
	cp -f ./inferelator.awf $(TARGET_DIR)
	echo "inferelator=$(DEPLOY_RUNTIME)/cmonkey-python/inferelator/\nujs_url=$(UJS_SERVICE_URL)\nawe_url=$(AWE_CLIENT_URL)\nid_url=$(ID_SERVICE_URL)\nws_url=$(WS_SERVICE_URL)\nawf_config=$(TARGET_DIR)/inferelator.awf" > $(TARGET_DIR)/inferelator.properties
	echo "./glassfish_start_service.sh $(TARGET_DIR)/service.war $(TARGET_PORT) $(THREADPOOL_SIZE)" > $(TARGET_DIR)/start_service
	chmod +x $(TARGET_DIR)/start_service
	echo "./glassfish_stop_service.sh $(TARGET_PORT)" > $(TARGET_DIR)/stop_service
	chmod +x $(TARGET_DIR)/stop_service

build-docs: compile-docs
	pod2html --infile=lib/Bio/KBase/$(SERVICE_NAME)/Client.pm --outfile=docs/$(SERVICE_NAME).html

compile-docs: build-libs

build-libs:
	./bin/compile_typespec \
		--psgi $(SERVICE_PSGI)  \
		--impl Bio::KBase::$(SERVICE_NAME)::$(SERVICE_NAME)Impl \
		--service Bio::KBase::$(SERVICE_NAME)::Service \
		--client Bio::KBase::$(SERVICE_NAME)::Client \
		--py biokbase/$(SERVICE_NAME)/Client \
		--js javascript/$(SERVICE_NAME)/Client \
		$(SERVICE_SPEC) lib

compile: src lib
	./make_war.sh $(SERVLET_CLASS)

test: test-scripts test-jar
	@echo "running script tests"

test-scripts:
	# run each test
	$(DEPLOY_RUNTIME)/bin/perl test/script_tests-command-line.t ; \
	if [ $$? -ne 0 ] ; then \
		exit 1 ; \
	fi \

test-jar:
	# run each test
	$(DEPLOY_RUNTIME)/bin/perl test/test_inferelator_server_invoker.t ; \
	if [ $$? -ne 0 ] ; then \
		exit 1 ; \
	fi \


clean:
	@echo "nothing to clean"
	
include $(TOP_DIR)/tools/Makefile.common.rules	
