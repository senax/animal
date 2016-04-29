module Animal
  class Root < Base
    get '/' do
      erb :main
    end

    get '/debug' do
      content_type :text
      return JSON.pretty_generate(request.env)
    end

  end # class
end # module
