.PHONY: help install test build rebuild clean sync-catalog publish publish-current

# VERSION is resolved from the gem's Ruby version constant so Make targets do
# not need manual edits every time you bump the release.
VERSION := $(shell ruby -e 'require_relative "lib/vietnam_qr_pay/version"; puts VietnamQrPay::VERSION')
# GEM_FILE expands to the exact artifact path for the current version.
# Example when VERSION=0.1.1:
#   $(GEM_FILE) => pkg/vietnam_qr_pay-0.1.1.gem
GEM_FILE := pkg/vietnam_qr_pay-$(VERSION).gem

help:
	@printf '%s\n' \
		'make install        # install/update bundle dependencies' \
		'make test           # run the test suite' \
		'make build          # build the gem for the current version' \
		'make rebuild        # clean pkg and build again' \
		'make clean          # remove built gem artifacts' \
		'make sync-catalog   # regenerate bank catalog from references/' \
		'make publish        # push the current version gem to RubyGems' \
		'make publish-current # alias of publish'

install:
	bundle install

test:
	bundle exec rake test

build:
	bundle exec rake build

rebuild: clean build

clean:
	rm -f pkg/*.gem

sync-catalog:
	ruby script/generate_catalog.rb

publish: build
	gem push $(GEM_FILE)

publish-current: publish
