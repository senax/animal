#!/bin/env ruby
require "pstore"

store = PStore.new("changes.pstore")

store.transaction(true) do
  store.roots.each do |root|
    puts root
    puts store[root].inspect
    puts
  end
end
