module Animal
  class Changes < Base
    def initialize(params)
      super
      if !defined?(@all_changes)
        @all_changes = get_changes()
      end
    end

    get '/changes' do
      @changes=@all_changes
      erb :changes
    end

    get '/change/:ref' do
      ref=params[:ref]
      @change=@all_changes[ref]
      erb :change, :layout => false
    end

    post '/change_classify/:ref' do
      ref=params[:ref]
      path=params[:path]
      value=params[:okay]
      basepath=@hiera.config[:yaml][:datadir]
      # puts "update #{path}.yaml, set #{ref} to #{value}"
      yamlfile={}
      if File.file?("#{basepath}/#{path}.yaml")
        yamlfile=YAML.load_file("#{basepath}/#{path}.yaml")
      end
      yamlfile[ref]=value
      if value.eql?("undef")
        yamlfile.delete(ref)
      end
      dirname=File.dirname("#{basepath}/#{path}.yaml")
      FileUtils.mkdir_p(dirname) unless File.exist?(dirname)
      File.open("#{basepath}/#{path}.yaml","w") do |h|
        h.write yamlfile.to_yaml
      end
      redirect "/change_classify/#{ref}"
    end

    get '/change_classify/:ref' do
      ref=params[:ref]
      @change=@all_changes[ref]
      @applies_to=[]
      get_nodes().each do |fqdn,val|
        if val[:changes].include?(ref) 
          @applies_to << {
            :params => val[:params],
            :targetenv => val[:targetenv],
            :age => val[:age],
          }
        end
      end

      param_combinations=[]
      @applies_to.each { |a|
        param_combinations << a[:params]
      }
      @hieratree=[]
      basepath=@hiera.config[:yaml][:datadir]
      @hiera.config[:hierarchy].each do |hier|
        param_combinations.uniq.each do |pc|
          interp=Hiera::Interpolate.interpolate(hier, pc,{})
          next if interp.match(/\/$/) # skip lines eding in /
          found="undef"
          if File.file?("#{basepath}/#{interp}.yaml")
            yamlfile=YAML.load_file("#{basepath}/#{interp}.yaml")
            if yamlfile.is_a?(Hash) and yamlfile.has_key?(ref)
              found=yamlfile[ref]
            end
          end
          @hieratree << { 
            :key => interp,
            :value => "#{basepath}/#{interp}.yaml contains #{ref} ?",
            :found => found,
          }
        end 
      end

      @hieratree.uniq!
      erb :change_classify
    end

    get '/change4node/:node/:targetenv/:ref' do
      node=params[:node]
      targetenv=params[:targetenv]
      ref=params[:ref]
      @change=@all_changes[ref]
      #      @change={} unless @change.is_a?(Hash)
      @change[:whitelist]=checkchange(ref,targetenv,getnodeparams(node))
      erb :change4node, :layout => false
    end

    get '/node_changes/:node' do
      node=params[:node]
      @node=get_node(node)
      # {:changes=>["d65d96b9ceaa3760f9667318a77fcf40"], :age=>235, :msgtime=>1433858894, :params=>{"fqdn"=>"lxdpuptst01v.foo.local", "location"=>"Waterhouse Square", "environment"=>"t2107855", "region"=>"UK", "bu"=>"M&G", "class"=>"Development", "role"=>"role_franktest"}, :targetenv=>"t2107855"}
      @node_changes=[]
      @stats={}
      @node[:changes].each do |ref|
        change=@all_changes[ref]
        change={} unless change.is_a?(Hash)
        change[:whitelist]=checkchange(ref,@node[:targetenv],getnodeparams(node))
        if @stats.has_key?(change[:whitelist])
          @stats[change[:whitelist]] += 1
        else
          @stats[change[:whitelist]] = 1
        end
        @node_changes << change
      end
      erb :node_changes
    end


  end # end class
end # end module
