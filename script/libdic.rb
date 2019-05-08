#!/usr/bin/env ruby
require 'libvarx'

module CIAX
  # Access :dic with get() directly
  module Dic
    def self.extended(obj)
      Msg.type?(obj, Varx)
    end

    # set dic
    def ext_dic(dicname)
      @dicname = dicname.to_sym
      return self if key?(@dicname)
      db = defined?(yield) ? yield : Hashx.new
      self[@dicname] = db
      self
    end

    # Never override the standard methods
    def get(id, &defproc)
      _dic.get(id, &defproc)
    end

    def put(id, obj, &done_proc)
      _dic.put(id, obj, &done_proc)
      cmt
    end

    def repl(id, val, &done_proc)
      _dic.repl(id, val, &done_proc)
      time_upd.cmt
    end

    def del(*keyary, &done_proc)
      _dic.del(*keyary, &done_proc)
      cmt
    end

    def cover(other)
      _dic.cover(other)
      cmt
    end

    def skeleton
      _dic.skeleton
    end

    def pick(*keyary)
      _dic.pick(*keyary)
    end

    def trues
      _dic.trues
    end

    def first
      _dic.first
    end

    private

    def _dic
      self[@dicname]
    end
  end

  # Key is Token (key1:key2:...)
  module DicToken
    include Dic
    def self.extended(obj)
      Msg.type?(obj, Hashx)
    end

    # key format: category + ':' followed by key "data:key, msg:key..."
    # default category is :data if no colon
    def get(token, &gen_proc)
      __get_db(token) do |db, id|
        db.get(id, &gen_proc)
      end || super
    end

    def put(token, obj, &done_proc)
      __get_db(token) do |db, id|
        db.put(id, obj, &done_proc)
      end && cmt || super
    end

    def repl(token, val, &done_proc)
      __get_db(token) do |db, id|
        db.repl(id, val, &done_proc)
      end && cmt || super
    end

    def del(*keyary, &done_proc)
      keyary.any? do |token|
        __get_db(token) do |db, id|
          db.del(id, &done_proc)
        end || super(token, &gen_proc)
      end && cmt
    end

    def pick(*keyary)
      keyary.each_with_object(Hashx.new) do |token, hash|
        __get_db(token) do |db, id|
          hash[token] = db[id] if db.key?(id)
        end
      end
    end

    private

    def __get_db(token)
      return if type?(token, String) !~ /:/
      cat, id = token.split(':')
      cat = cat.to_sym
      par_err("Invalid category (#{cat}/#{key})") unless key?(cat)
      par_err("Invalid id (#{cat}:#{id})") unless self[cat].key?(id)
      yield(self[cat], id)
    end
  end
end
