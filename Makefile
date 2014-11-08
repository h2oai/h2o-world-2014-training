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

test:
	s3cmd sync --dry-run --delete-removed --acl-public --exclude-from s3.exclude build/site s3://0xdata.com/

stage:
	s3cmd sync --delete-removed --acl-public --exclude-from s3.exclude build/site s3://stage.0xdata.com/

push:
	s3cmd sync --delete-removed --acl-public --exclude-from s3.exclude build/site s3://0xdata.com/

build/site-src: 
	rsync -rupE tools/site-src build/
	rsync -rupE tutorials/ build/site-src/

mrproper: clean
	rm -rf node_modules/

.PHONY: build run clean test push build/site-src
