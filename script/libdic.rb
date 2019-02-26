#!/usr/bin/env ruby
require 'libvarx'

module CIAX
  # Access :dic with get() directly
  module Dic
    attr_reader :dic
    def self.extended(obj)
      Msg.type?(obj, Varx)
    end

    # set dic
    def ext_dic(dicname)
      return self if key?(dicname)
      db = defined?(yield) ? yield : Hashx.new
      @dic = self[dicname] = db
      self
    end

    # Never override the standard methods
    def get(id, &defproc)
      @dic.get(id, &defproc)
    end

    def put(id, obj)
      @dic.put(id, obj)
      cmt
    end
  end

  # Key is Token
  module DicToken
    def self.extended(obj)
      Msg.type?(obj, Hashx)
    end

    # key format: category + ':' followed by key "data:key, msg:key..."
    # default category is :data if no colon
    def get(key, &gen_proc)
      cat, id = __get_key(key)
      self[cat].get(id, &gen_proc)
    end

    private

    def __get_key(key)
      type?(key, String)
      key = 'data:' + key if key !~ /:/
      cat, id = key.split(':')
      cat = cat.to_sym
      par_err("Invalid category (#{cat})") unless key?(cat)
      par_err("Invalid id (#{cat}:#{id})") unless id && self[cat].key?(id)
      [cat, id]
    end
  end
end
