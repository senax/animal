module Animal
  class Base < Sinatra::Base

    require 'logger'
    require 'json'
    require 'yaml'
    require 'date'
    require "pstore"
    require "time"
    require 'hiera'
    require 'puppet'

    configure do
      set :views, 'views'
      set :root, File.dirname(__FILE__)
    end

    def initialize(params)
      super
      if !defined?(@nodes_store)
        @nodes_store = PStore.new("/home/t2107855/GIT/animal2/nodes.pstore")
      end
      if !defined?(@changes_store)
        @changes_store = PStore.new("/home/t2107855/GIT/animal2/changes.pstore")
      end
      if !defined?(@hiera)
        @hiera = Hiera.new(:config => "/home/t2107855/GIT/animal-web/hiera.yaml")
        keys=[]
        @hiera_keys=@hiera.config[:hierarchy].join(' ').scan(/%\{([^\}]*)\}/).flatten
        @hiera_keys << 'environment' # <-- overwritten to foreman_env below!
        # ["bu/%{bu}", "region/%{region}", "common"]
      end
      if !defined?(@nodes_params)
        @nodes_params={}
      end
    end

    def get_node(node_name)
      all_nodes=get_nodes()
      all_nodes[node_name]
    end

    def get_nodes
      return @nodes if defined?(@nodes) and @nodes.size > 1
      nodes={}
      @nodes_store.transaction(true) do
        @nodes_store.roots.each do |n|
          nodes[n]={}
          nodes[n][:targetenv]=@nodes_store[n][:targetenv]
          nodes[n][:msgtime]=@nodes_store[n][:msgtime]
          nodes[n][:age]= Time.new().to_i - @nodes_store[n][:msgtime].to_i
#          nodes[n][:changes]=@nodes_store[n][:changes]
          nodes[n][:params]=getnodeparams(n)
          nodes[n][:params]["targetenv"]=@nodes_store[n][:targetenv]
          nodes[n][:changes]={}
          nodes[n][:stats]={'false' => 0, 'true' => 0, 'unknown' => 0, }
          @nodes_store[n][:changes].each do |ref|
              result=checkchange(ref,nodes[n][:params]["targetenv"],nodes[n][:params])
              nodes[n][:changes][ref]=result
              nodes[n][:stats][result] += 1
          end
        end
      end
      nodes
    end

    def getnodeparams(node_name)
      if not @nodes_params.has_key?(node_name)
        scope={}
        scope["fqdn"]=node_name
        params={}
        params["fqdn"]=node_name
        @hiera_keys.each do |key|
          next if key.eql?('fqdn')
          if key.eql?('bu')
            params[key]=@hiera.lookup(key.upcase,nil,scope)
          elsif key.eql?('role')
            params[key]=@hiera.lookup('classes',nil,scope)[0]
          elsif key.eql?('environment')
            params[key]=@hiera.lookup('foreman_env',nil,scope)
          else
            params[key]=@hiera.lookup(key,nil,scope)
          end
        end
        @nodes_params[node_name]=params
      end
      @nodes_params[node_name]
    end

    def checkchange(ref,targetenv,node_params)
      # check if ref is whitelisted for node_params
      node_params["environment"]=targetenv
      @hiera.lookup(ref,"unknown",node_params)
    end

    def get_changes
      changes={}
      @changes_store.transaction(true) do
        @changes_store.roots.each do |c|
          changes[c]={}
          changes[c]=@changes_store[c]
        end
      end
      changes
    end

    def get_change(ref)
      change=nil
      @changes_store.transaction(true) do
        if @changes_store.root?(ref)
          change={}
          change=@changes_store[ref]
        end
      end
      change
    end

  end # class
end # modules
