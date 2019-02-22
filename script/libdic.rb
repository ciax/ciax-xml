#!/usr/bin/env ruby
require 'libvarx'

module CIAX
  # Access :dic with get() directly
  module Dic
    attr_reader :dic
    def self.extended(obj)
      Msg.type?(obj, Varx)
    end

    def ext_dic(dicname)
      @dic = type?(self[dicname] ||= Hashx.new, Hashx)
      self
    end

    # Never override the standard methods
    def get(id)
      @dic.get(id)
    end

    def put(id, obj)
      @dic.put(id, obj)
      cmt
    end
  end
end
