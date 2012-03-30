#!/usr/bin/ruby
require 'libmsg'
#Extened Hash
module ExEnum
  def to_s
    Msg.view_struct(self)
  end

  def attr_update(obj)
    case obj
    when Hash
      ary=obj.keys
    when Array
      ary=obj.size.times
    end
    ary.each{|i| self[i]=obj[i] if Comparable === obj[i]}
    self
  end

  def deep_copy
    Marshal.load(Marshal.dump(self))
  end

  # Freeze one level deepth or more
  def deep_freeze
    rec_proc(self){|i| i.freeze }
    self
  end

  # Merge self to obj
  def deep_update(obj)
    rec_merge(obj,self)
    self
  end

  private
  # a will be merged to b (b is changed)
  def rec_merge(a,b)
    case a
    when Hash
      b= b.is_a?(Hash) ? b : {}
      a.keys.each{|i| b[i]=rec_merge(a[i],b[i]) }
    when Array
      b= b.is_a?(Array) ? b : []
      a.size.times{|i| b[i]=rec_merge(a[i],b[i]) }
    else
      b=a||b
    end
    b
  end

  def rec_proc(db)
    case db
    when Hash
      db.keys.each{|i| rec_proc(db[i]){|i| yield i} }
    when Array
      db.size.times{|i| rec_proc(db[i]){|i| yield i} }
    end
    yield db
  end
end

class ExHash < Hash
  include ExEnum
end

class ExArray < Array
  include ExEnum
end
