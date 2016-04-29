module Animal
  class Nodes < Base

    def initialize(params)
      super
      if !defined?(@all_changes)
        @all_changes = get_changes()
      end
    end


    get '/nodes' do
      @nodes=get_nodes()
      #@changes=@all_changes
      @changes=get_changes()
      erb :nodes
    end

    #    get '/nnnnode_changes/:node' do
    #      node=params[:node]
    #      @node=get_node(node)
    #      erb :node_changes
    #    end


  end # end class
end # end module
