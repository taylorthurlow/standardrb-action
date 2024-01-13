#!/bin/sh

set -e

if [[ $STANDARD_VERSION ]]; then
	echo "STANDARD_VERSION set, installing specified version"
	gem install standard -v "$STANDARD_VERSION"
else
	echo "STANDARD_VERSION not set, installing latest version"
	gem install standard
fi

ruby /action/lib/index.rb
