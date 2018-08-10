test: unittest rspec cucumber
htmlcov/index.html:
	coverage run -m unittest discover && coverage html --include="*/vdebug/*"
unittest:
	python3 -m unittest discover
rspec: vendor/bundle
	bundle exec rspec spec/*_spec.rb
cucumber: vendor/bundle
	bundle exec cucumber features --format pretty
vendor/bundle: Gemfile
	bundle install --path $@
.PHONY: test rspec cucumber
