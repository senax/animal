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
mc.timeout = 600
mc.ttl = 600
mc.batch_size = 10
mc.batch_sleep_time = 1
mc.verbose = true
mc.progress = true
#mc.identity_filter "lxdpuptst02v.pgds.local"
mc.discover(:nodes => ['lxdpuptst01v.pgds.local','lxdpuptst02v.pgds.local',])
#mc.check(:environment => "t2107855", :tags => ['cis','ntp_pgds',]) do |resp|
mc.check(:environment => targetenv) do |resp|

  p resp if resp[:body][:statuscode] != 0
  next if resp[:body][:statuscode] != 0
  begin
    resp[:targetenv] = targetenv
    resp[:changes] = []
    begin
      output=JSON.parse(resp[:body][:data][:output] + ']')
    rescue
      puts "host #{resp[:senderid]}"
      puts "No json? #{resp[:body][:data][:output]}"
      output=[]
    end

      output.each do |event|
        event["type"]="unknown"

        #{"type"=>"unknown", "message"=>"Caching catalog for lxdpuptst02v.pgds.local", "source"=>"Puppet", "tags"=>["info"], "time"=>"2015-06-09T10:09:37.732142000+01:00", "level"=>"info"}
        # {"tags"=>["info"], "source"=>"Puppet", "time"=>"2015-06-09T10:09:12.947611000+01:00", "type"=>"unknown", "level"=>"info", "message"=>"Retrieving plugin"}
        # {"type"=>"ignore", "message"=>"Applying configuration version 't2107855'", "source"=>"Puppet", "tags"=>["info"], "time"=>"2015-06-09T10:09:39.443344000+01:00", "level"=>"info"}
        # {"type"=>"ignore", "message"=>"Applying configuration version 't2107855'", "source"=>"Puppet", "tags"=>["info"], "time"=>"2015-06-09T10:09:39.443344000+01:00", "level"=>"info"}
        # {"type"=>"ignore", "message"=>"Finished catalog run in 63.25 seconds", "source"=>"Puppet", "tags"=>["notice"], "time"=>"2015-06-09T10:10:42.270191000+01:00", "level"=>"notice"}
        event["type"]="ignore" if event["source"].eql?("Puppet")

        #  {"file"=>"/etc/puppet/environments/t2107855/modules/int/cron/manifests/init.pp", "time"=>"2015-06-09T10:09:42.087771000+01:00", "level"=>"notice", "line"=>10, "type"=>"unknown", "tags"=>["cron", "content", "class", "file", "role_franktest", "profile_franktest", "profile_vanilla", "notice"], "message"=>"\n--- /etc/at.allow\t2015-06-02 14:54:18.040000040 +0100\n+++ /tmp/puppet-file20150609-11793-1vxlvzd-0\t2015-06-09 10", "source"=>"/Stage[main]/Cron/File[/etc/at.allow]/content"}
        #  "current_value {md5}d41d8cd98f00b204e9800998ecf8427e, should be {md5}1a0795a25df8ec592cd1c660e15f0621 (noop)"
        event["type"]="filechange" if \
          event["level"].eql?("notice") \
          and event["source"].match(/\/content$/) \
          and event["tags"].include?("file") \
          and not event["message"].match(/^current_value \{md5\}\w+, should be \{md5\}\w+ \(noop\)/)

        # {"tags"=>["cron", "class", "file", "role_franktest", "profile_franktest", "profile_vanilla", "notice"], "time"=>"2015-06-09T10:09:42.089548000+01:00", "level"=>"notice", "type"=>"unknown", "file"=>"/etc/puppet/environments/t2107855/modules/int/cron/manifests/init.pp", "line"=>10, "message"=>"current_value {md5}d41d8cd98f00b204e9800998ecf8427e, should be {md5}1a0795a25df8ec592cd1c660e15f0621 (noop)", "source"=>"/Stage[main]/Cron/File[/etc/at.allow]/content"}
        # {"source"=>"/Stage[main]/Pgds_tools::Opt_local/File[/opt/local/sbin/rhaudit5]/content", "type"=>"unknown", "tags"=>["class", "pgds_tools", "opt_local", "role_franktest", "file", "profile_franktest", "profile_vanilla", "pgds_tools::opt_local", "notice"], "time"=>"2015-06-09T10:10:19.827459000+01:00", "level"=>"notice", "message"=>"current_value {md5}90bacfa02c3a02538e0fbccfc2702ef3, should be {md5}fec5fd85b5a53fe713e1fc4ed2c8822e (noop)"}
        # and event.has_key?("file") \
        event["type"]="ignore" if \
          event["level"].eql?("notice") \
          and event["tags"].include?("file") \
          and event["message"].match(/^current_value \{md5\}\w+, should be \{md5\}\w+ \(noop\)/)

        # {"tags"=>["completed_class", "ntp", "ntp::config", "config", "notice"], "time"=>"2015-06-09T10:10:16.312522000+01:00", "level"=>"notice", "type"=>"unknown", "message"=>"Would have triggered 'refresh' from 1 events", "source"=>"Class[Ntp::Config]"}
        event["type"]="ignore" if \
          event["level"].eql?("notice") \
          and event["message"].match(/^Would have triggered 'refresh' from \d+ events/)

        # {"type"=>"unknown", "level"=>"info", "message"=>"Scheduling refresh of Class[Ntp::Service]", "source"=>"Class[Ntp::Config]", "tags"=>["completed_class", "ntp", "ntp::config", "config", "info"], "time"=>"2015-06-09T10:10:16.313996000+01:00"}
        event["type"]="refresh" if \
          event["level"].eql?("info") \
          and event["tags"].include?("admissible_class") \
          and event["message"].match(/^Scheduling refresh of/)

        # {"level"=>"info", "source"=>"Class[Ntp::Config]", "message"=>"Scheduling refresh of Class[Ntp::Service]", "type"=>"unknown", "tags"=>["completed_class", "ntp", "ntp::config", "config", "info"], "time"=>"2015-06-09T10:10:16.313996000+01:00"}
        event["type"]="ignore" if \
          event["level"].eql?("info") \
          and event["tags"].include?("completed_class") \
          and event["message"].match(/^Scheduling refresh of/)

        # {"line"=>81, "type"=>"unknown", "tags"=>["rebuild_sendmail", "sendmail", "exec", "sendmail::config", "class", "config", "role_franktest", "profile_franktest", "profile_vanilla", "info"], "time"=>"2015-06-09T10:10:35.011664000+01:00", "message"=>"Scheduling refresh of Service[sendmail]", "file"=>"/etc/puppet/environments/t2107855/modules/int/sendmail/manifests/config.pp", "level"=>"info", "source"=>"/Stage[main]/Sendmail::Config/Exec[rebuild_sendmail]"}
        event["type"]="refresh" if \
          event["level"].eql?("info") \
          and event["source"].match(/^\/Stage/) \
          and event["message"].match(/^Scheduling refresh of/)

        # {"message"=>"current_value absent, should be file (noop)", "source"=>"/Stage[main]/Pgds_tools::Opt_local/File[/opt/local/sbin/remove_user]/ensure", "tags"=>["class", "pgds_tools", "opt_local", "role_franktest", "file", "profile_franktest", "profile_vanilla", "pgds_tools::opt_local", "notice"], "time"=>"2015-06-09T10:10:21.008155000+01:00", "level"=>"notice", "type"=>"unknown"}
        event["type"]="newfile" if \
          event["level"].eql?("notice") \
          and event["tags"].include?("file") \
          and event["source"].match(/\/ensure$/) \
          and event["message"].match(/^current_value absent, should be/)

        # {"level"=>"notice", "line"=>245, "type"=>"newfile", "file"=>"/etc/puppet/environments/t2107855/modules/int/pgds_tools/manifests/packages.pp", "source"=>"/Stage[main]/Pgds_tools::Packages/Package[dump]/ensure", "message"=>"current_value absent, should be present (noop)", "tags"=>["profile_franktest", "packages", "dump", "class", "pgds_tools", "role_franktest", "package", "pgds_tools::packages", "notice"], "time"=>"2015-06-09T13:05:41.842852000+01:00"} 
        event["type"]="newpackage" if \
          event["level"].eql?("notice") \
          and event["tags"].include?("packages") \
          and event["source"].match(/\/ensure$/) \
          and event["message"].match(/^current_value absent, should be/)

        event["type"]="error" if \
          event["level"].eql?("err")


        if event["type"].eql?("filechange")
          # "message"=>"\n--- /usr/libexec/mcollective/mcollective/agent/gonzo.rb\t2015-06-08 17:14:38.754646767 +0100\n+++ /tmp/puppet-file20150609-15413-48478w-0\t2015-06-09 13:05:55.643138263 +0100\n@@ -75,8 +75,7 @@
          event["message"].gsub!(/(\n--- \/.*)\t.*$/,'\1')
          event["message"].gsub!(/(\n\+\+\+ )\/.*\t.*$/,'\1')
        end

        next if event["type"].eql?("ignore")
        # next unless event["type"].eql?("filechange")

        event["ref"]=Digest::MD5.hexdigest( event["source"] + event["level"] + event["message"] )
        event.delete("tags")
        event.delete("time")
        #      event.each_pair do |k,v|
        #        next if k.eql?("tags")
        #        next if k.eql?("time")
        #        puts "#{k}\t#{v.to_s[0..100]}"
        #      end
#        p event
#        puts
        all_changes[event["ref"]]=event
        resp[:changes] << event["ref"]
      end
      # Save the report
      all_nodes[resp[:senderid]] = resp

  rescue => e
    puts "The RPC agent returned an error: #{e}"
  end
end # mc.check utp
puts "---------------------------------------"
changes_store = PStore.new("changes.pstore")
changes_store.transaction do
  all_changes.each do |k,v|
    changes_store[k] = v unless changes_store.root?(k)
  end
end
nodes_store = PStore.new("nodes.pstore")
nodes_store.transaction do
  all_nodes.each do |k,v|
    nodes_store[k] = v
  end
end
printrpcstats
mc.disconnect
# %x{mco rpc gonzo check environment=t2107855 --with-identity lxdpuptst01v.pgds.local --json}

