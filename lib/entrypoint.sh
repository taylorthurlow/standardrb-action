#!/bin/sh

set -e

if [ -n $STANDARD_VERSION ]; then
	echo "STANDARD_VERSION set, installing specified version"
	gem install standard -v "$STANDARD_VERSION"
else
	echo "STANDARD_VERSION not set, installing latest version"
	gem install standard
fi

if [ -n $ADDITIONAL_INSTALLED_GEMS ]; then
  gem install $ADDITIONAL_INSTALLED_GEMS
fi

ruby /action/lib/index.rb
