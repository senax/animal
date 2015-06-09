#!/bin/env ruby
#
require 'rubygems'
require 'mcollective'
require 'mcollective/cache'
require 'digest/md5'
require 'json'
require 'pstore'

include MCollective::RPC

# Setup cache
MCollective::Cache.setup(:release_results, 600)

all_changes={}
all_nodes={}

targetenv = "t2107855"
mc = rpcclient("gonzo", {:color => "false"})
mc.verbose = true
mc.progress = true
#mc.identity_filter "lxdpuptst01v.pgds.local"
#mc.discover(:nodes => ['lxdpuptst01v.pgds.local','lxdpuptst02v.pgds.local',])
#mc.check(:environment => "t2107855", :tags => ['cis','ntp_pgds',]) do |resp|
mc.check(:environment => targetenv) do |resp|
  begin
    resp[:targetenv] = targetenv

    resp[:collection] = "report"
    resp[:changes] = []
    resp[:body][:data][:out].each_line do |line|
      # New change block starting with xxxx:
      if line.match(/^[A-Z][a-z]*:/)
        # Previous block needs to be saved
        unless @changeref.nil?
          # If we've saved this change before, replace the current block with it
          change = Hash[:ref => @changeref, :output => @block, ]
          all_changes[@changeref]=change
          resp[:changes] << @changeref
          @changeref = nil
          @block = nil
        end # end unless nil
        case line
          when /^Info:/,
               /^Notice: Finished catalog run/,
               /^Notice: .*\/File\[.*\]\/content: current_value \{md5\}[a-f0-9]*, should be/
            @skip = true
          else
            @skip = false
            if @block.nil?
              @changeref = Digest::MD5.hexdigest(line.strip)
            else
              @changeref = Digest::MD5.hexdigest(@block)
            end # end block.nil?
          end # end else
        end # case
        unless @skip
          (@block ||= "") << line
        end
      end

    # Save the report
    all_nodes[resp[:senderid]] = resp
  rescue RPCError => e
    puts "The RPC agent returned an error: #{e}"
  end
end # mc.check utp
puts "---------------------------------------"
changes_store = PStore.new("2changes.pstore")
changes_store.transaction do
  all_changes.each do |k,v|
    changes_store[k] = v unless changes_store.root?(k)
  end
end
nodes_store = PStore.new("2nodes.pstore")
nodes_store.transaction do
  all_nodes.each do |k,v|
    nodes_store[k] = v
  end
end
printrpcstats
mc.disconnect
# %x{mco rpc gonzo check environment=t2107855 --with-identity lxdpuptst01v.pgds.local --json}

