#!/usr/bin/env ruby
require 'libvarx'

module CIAX
  # Access :dic with get() directly
  module Dic
    attr_reader :dic
    def self.extended(obj)
      Msg.type?(obj, Varx)
    end

    # db is source of skelton
    def ext_dic(dicname, db = {})
      @dic = self[dicname] = Hashx.new(db).skeleton
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
