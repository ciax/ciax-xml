#!/usr/bin/env ruby
require 'libvarx'

module CIAX
  # Access :dic with get() directly
  module Dic
    def self.extended(obj)
      Msg.type?(obj, Varx)
    end

    def ext_dic(dicname)
      @dic = type?(self[dicname] ||= Hashx.new, Hashx)
      self
    end

    def replace(h)
      @dic.replace(h)
      cmt
    end

    def key?(id)
      @dic.key?(id)
    end

    def keys
      @dic.keys
    end

    def get(id)
      @dic.get(id)
    end

    def put(id, obj)
      @dic.put(id, obj)
      cmt
    end

    def to_a
      @dic.keys
    end

    def each
      @dic.each { |k, v| yield k, v }
    end
  end
end
