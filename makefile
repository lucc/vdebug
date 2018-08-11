VERSION = $(shell cat VERSION)
FILES = doc plugin python3 syntax CHANGELOG LICENCE README.md VERSION

# abstract targets for the user
test: unittest rspec cucumber
tarball: vdebug-$(VERSION).tar.gz
coverage: htmlcov/index.html
# abstract targets to run individual test suits
unittest:
	python3 -m unittest discover
rspec: vendor/bundle
	bundle exec rspec spec/*_spec.rb
cucumber: vendor/bundle
	bundle exec cucumber features --format pretty
.PHONY: test tarball coverage unittest rspec cucumber

# Backend targets to produce some files
vendor/bundle: Gemfile
	bundle install --path $@
vdebug-$(VERSION).tar.gz: $(FILES)
	tar -cvzf $@ $(FILES)
htmlcov/index.html:
	coverage run -m unittest discover
	coverage html --include="python3/vdebug/*"
