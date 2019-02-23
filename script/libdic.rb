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
end
