#!/bin/bash

export GEM_HOME=./gems
export PATH=$PATH:$GEM_HOME/bin/:./gems/bin:./vendor/bundle/ruby/1.8/bin/

bundle exec rackup -o '0.0.0.0' -p 9293

