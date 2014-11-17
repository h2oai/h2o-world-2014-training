build: node_modules build/site-src
	node_modules/.bin/coffee tools/fuse.coffee build/site-src build/site

run: node_modules
	@echo "Go to http://localhost:8080/"
	node_modules/.bin/coffee tools/server.coffee build/site

# After 'make run' you can do this to get to the web site.
browser_on_mac:
	open http://localhost:8080

clean:
	rm -rf build

node_modules: package.json
	npm install

build/site-src: 
	rsync -rupE tools/site-src build/
	rsync -rupE tutorials/ build/site-src/

mrproper: clean
	rm -rf node_modules/

install:
	rm -rf /opt/h2o-training
	cp -r build/site/ /opt/h2o-training

test:
	s3cmd sync --dry-run --delete-removed --acl-public --exclude-from s3.exclude build/site/ s3://train.h2o.ai/

push:
	s3cmd sync --delete-removed --acl-public --exclude-from s3.exclude build/site/ s3://train.h2o.ai/

.PHONY: build run clean test push build/site-src test
