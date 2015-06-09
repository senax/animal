#!/bin/env ruby
require "pstore"

store = PStore.new("changes.pstore")

store.transaction(true) do
  store.roots.each do |root|
    puts "----------------------------------------------------------"
    puts "----------------------------------------------------------"
    puts store[root].inspect
    puts "----------------------------------------------------------"
    puts root
#    puts store[root][:output]
  end
end
