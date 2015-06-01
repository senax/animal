#!/bin/env ruby
require "pstore"
require "time"

store = PStore.new("nodes.pstore")

store.transaction(true) do
  store.roots.each do |root|
    puts root
#    puts store[root].inspect
    puts store[root][:targetenv]
    age = Time.new().to_i - store[root][:msgtime].to_i
    puts store[root][:msgtime]
    puts "age: #{age} seconds"
    puts store[root][:changes].join(',').to_s
  end
end
