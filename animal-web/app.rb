require 'rubygems'
require 'bundler'

Bundler.require

require 'sinatra/base'
require 'sinatra/reloader'
require './app/base'

module Animal
  class App < Sinatra::Application

    configure do
      set :bind, '0.0.0.0'
      set :port, '9293'
      set :sessions,
        :httponly => true,
        #        :secure => production?,
        :expire_after => 3600,
        :secret => 'kfjgfkjgkfhdgjlhfdjghfgfdgi48578475t'
      set :logging, true
      set :root, File.dirname(__FILE__)
      use Rack::Session::Pool, :expire_after => 300
      set :protection, :session => true, :except => :session_hijacking
    end

    require './app/root'
    use Animal::Root
    require './app/nodes'
    use Animal::Nodes
    require './app/changes'
    use Animal::Changes
    #
    use Rack::Deflater
    #    run! if app_file == $0
  end
end
