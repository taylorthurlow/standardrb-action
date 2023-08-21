#!/bin/sh

set -e

gem install standard $ADDITIONAL_INSTALLED_GEMS

ruby /action/lib/index.rb
