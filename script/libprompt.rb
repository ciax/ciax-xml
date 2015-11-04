#!/usr/bin/ruby
require 'libvarx'
module CIAX
  # For server status through all layers
  class Prompt < Varx
    NS_COLOR = 9
    attr_reader :db
    def initialize(id)
      super('server',id)
      @db = {}
      self['msg'] = ''
    end

    def add_db(db = {})
      @db.update(type?(db, Hash))
      self
    end

    def set(key)
      pre_upd
      self[key] = true
      verbose { "Set [#{key}]" }
      self
    ensure
      post_upd
    end

    def reset(key)
      pre_upd
      self[key] = false
      verbose { "Reset [#{key}]" }
      self
    ensure
      post_upd
    end

    def put(key, val)
      verbose { "Change [#{key}] -> #{val}" }
      super
    end

    # Subtract and merge to self data, return rest of the data
    def sub(input)
      pre_upd
      hash = input.dup
      @db.keys.each do|k|
        self[k] = hash[k] ? hash.delete(k) : false
      end
      hash
    ensure
      post_upd
    end

    def msg(msg = nil)
      self['msg'] = msg if msg
      self['msg']
    end

    def to_s
      verbose { "Shell\n" + inspect }
      @db.map { |k, v| v if self[k] }.join('')
    end
  end
end
