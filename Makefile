SRC = $(shell find test/cases -name client -prune -o -name '*Test.coffee' -print)
STORES = memory mongodb
CMD = ./node_modules/mocha/bin/mocha
DIR = $(shell pwd)
GRUNT = grunt
FOREVER = forever
PORT = 3210
TEST_URL = http://localhost:$(PORT)/?test=support,application,store,model
CLIENT_PID = null
TEST_SERVER_PATH = test/example/server

check-grunt:
ifeq ($(shell which $(GRUNT)),)
	$(eval GRUNT = $(shell pwd)/node_modules/grunt/bin/grunt)
ifeq ($(shell which ./node_modules/grunt/bin/grunt),)	
	npm install grunt
endif
endif

check-forever:
ifeq ($(shell which $(FOREVER)),)
	$(eval FOREVER = $(shell pwd)/node_modules/forever/bin/forever)
ifeq ($(shell which ./node_modules/forever/bin/forever),)	
	npm install forever
endif
endif

# ps -ef | awk '/node server -p 3210/{print $2}' | wc -l | awk '{print $1}'
# check-server: check-forever

check-phantomjs:
ifeq ($(shell which phantomjs),) # if it's blank
	$(error PhantomJS is not installed. Download from http://phantomjs.org or run `brew install phantomjs` if you have Homebrew)
endif

test: test-memory test-mongodb

test-memory:
	$(CMD) $(SRC) --store memory

test-mongodb:
	$(CMD) $(SRC) --store mongodb

test-client:
	phantomjs test/client.coffee $(TEST_URL)

setup-test-client: check-phantomjs check-grunt
	# tmp way of downloading vendor files
	rm -rf test/example/vendor
	./bin/tower new example
	mv example/vendor test/example
	rm -rf ./example
	$(GRUNT) --config ./grunt.coffee
	cd test/example && pwd && npm install .
	$(GRUNT) --config ./test/example/grunt.coffee

start-test-client:
	node $(TEST_SERVER_PATH) -p $(PORT)

start-test-client-conditionally: test-client-pid
ifeq ($(CLIENT_PID),)
	$(shell node $(TEST_SERVER_PATH) -p $(PORT) &)
else
	@echo Server already running on port $(PORT)
endif

test-client-pid:
	$(eval CLIENT_PID = $(call get-pids,node $(TEST_SERVER_PATH)))
	@echo $(CLIENT_PID): node $(TEST_SERVER_PATH) -p $(PORT)

stop-test-client: test-client-pid

client: start-test-client test-client

define open-browser
	open -a "$(1)" $(TEST_URL)\&complete=close
endef

test-firefox:
	$(call open-browser,Firefox)

test-safari:
	$(call open-browser,Safari)

test-chrome:
	$(call open-browser,"Google\ Chrome")

test-opera:
	$(call open-browser,Opera)

test-all:
	for i in $(STORES); do ./node_modules/mocha/bin/mocha $(SRC) --store $$i; done

clean:
	rm -rf dist/*
	rm -rf lib/*

whitespace:
	cake clean

install:
	npm install
	npm install-dev

watch: clean
	$(GRUNT) start --config ./grunt.coffee

build:
	$(GRUNT) build:client --config ./grunt.coffee

dist:
	$(GRUNT) dist --config ./grunt.coffee

publish:
	npm publish

define kill-processes
	@echo 'killing processes...'
	@echo $(call get-processes,$(1))
	kill -9 $(call get-pids,$(1))
endef

define get-pids
	$(shell ps -ef | grep -e '$(1)' | grep -v grep | awk '{print $$2}')
endef

define get-processes
	$(shell ps -ef | grep -e '$(1)' | grep -v grep)
endef

.PHONY: test-memory test-mongodb test test-all test-client build dist check-phantomjs check-grunt check-forever setup-test-client start-test-client
