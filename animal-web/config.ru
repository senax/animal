#]ENV['GEM_HOME']='0gems'
require 'sinatra/reloader'
require './app'
# run with:  bundle exec rackup

#export GEM_HOME=~/.gems
#export PATH=$PATH:$GEM_HOME/bin/:./gems/bin:./vendor/bundle/ruby/1.8/bin/

#set :bind => '0.0.0.0'

run Animal::App
