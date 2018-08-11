VERSION = $(shell cat VERSION)
FILES = doc plugin python3 syntax CHANGELOG LICENCE README.md VERSION
test: unittest rspec cucumber
tarball: vdebug-$(VERSION).tar.gz
htmlcov/index.html:
	coverage run -m unittest discover
	coverage html --include="python3/vdebug/*"
unittest:
	python3 -m unittest discover
rspec: vendor/bundle
	bundle exec rspec spec/*_spec.rb
cucumber: vendor/bundle
	bundle exec cucumber features --format pretty
vendor/bundle: Gemfile
	bundle install --path $@
vdebug-$(VERSION).tar.gz: $(FILES)
	tar -cvzf $@ $(FILES)
.PHONY: test rspec cucumber tarball
