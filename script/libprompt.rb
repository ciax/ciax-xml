#!/usr/bin/ruby
require 'libupd'
module CIAX
  # For server status through all layers
  class Prompt < Upd
    attr_reader :db
    def initialize
      super()
      @db = {}
      self['msg'] = ''
    end

    def add_db(db = {})
      @db.update(type?(db, Hash))
      self
    end

    def set(key)
      self[key] = true
      verbose { "Set [#{key}]" }
      upd
    end

    def reset(key)
      self[key] = false
      verbose { "Reset [#{key}]" }
      upd
    end

    def put(key, val)
      verbose { "Change [#{key}] -> #{val}" }
      super
    end

    # Subtract and merge to self data, return rest of the data
    def sub(input)
      hash = input.dup
      @db.keys.each do|k|
        self[k] = hash[k] ? hash.delete(k) : false
      end
      hash
    end

    def msg(msg = nil)
      self['msg'] = msg if msg
      self['msg']
    end

    def to_s
      verbose { ['Shell', inspect] }
      @db.map { |k, v| v if self[k] }.join('')
    end
  end
end
