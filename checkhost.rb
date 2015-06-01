#!/bin/env ruby
#
require 'rubygems'
require 'mcollective'
require 'mcollective/cache'
require 'digest/md5'
require 'json'

include MCollective::RPC

# Setup cache
MCollective::Cache.setup(:release_results, 600)

targetenv = "t2107855"
mc = rpcclient("gonzo", {:color => "false"})
mc.verbose = false
mc.progress = true
mc.identity_filter "lxdpuptst02v.pgds.local"
#mc.discover(:nodes => ['lxdpuptst01v.pgds.local','lxdpuptst02v.pgds.local',])
#mc.check(:environment => "t2107855", :tags => ['cis','ntp_pgds',]) do |resp|
mc.check(:environment => targetenv) do |resp|
  begin
    resp[:targetenev] = targetenv

    resp[:collection] = "report"
    resp[:changes] = []
    resp[:body][:data][:out].each_line do |line|
      # New change block starting with xxxx:
      if line.match(/^[A-Z][a-z]*:/)

        # Previous block needs to be saved
        unless @changeref.nil?
          # If we've saved this change before, replace the current block with it
          begin
            change = MCollective::Cache.read(:release_results, @changeref)
          rescue
            change = Hash[:collection => 'change', :output => @block, ]
            begin
              MCollective::Cache.write(:release_results, @changeref, change)
            rescue
              puts "#{resp[:senderid]}: Error writing: #{@changeref}"
            end
          end

          puts "--------------"
          p @changeref
          p change
          #        save(@changeref, change)
          resp[:changes] << @changeref
          @changeref = nil
          @block = nil
        end
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
          end
        end
      end
      unless @skip
        (@block ||= "") << line
      end
    end

    # Save the report
    puts "--------------"
    p resp[:senderid]
    p resp[:changes]
    p resp[:msgtime]
    p resp[:body][:statusmsg]
    #save(resp[:senderid], resp)
  rescue RPCError => e
    puts "The RPC agent returned an error: #{e}"
  end

end
puts "---------------------------------------"
printrpcstats
mc.disconnect
# %x{mco rpc gonzo check environment=t2107855 --with-identity lxdpuptst01v.pgds.local --json}

