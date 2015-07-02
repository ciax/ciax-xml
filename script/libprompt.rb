#!/usr/bin/ruby
require "libenumx"
module CIAX
  # For server status through all layers
  class Prompt < Hashx
    attr_reader :db
    def initialize
      super()
      @db={}
    end

    def add_db(db={})
      @db.update(type?(db,Hash))
      self
    end

    # Pick up and merge to self data, return other data
    def pick(input)
      hash=input.dup
      @db.keys.each{|k|
        self[k]= hash[k] ? hash.delete(k) : false
      }
      hash
    end

    def to_s
      verbose("Shell",inspect)
      @db.map{|k,v| v if self[k] }.join('')
    end
  end
end
