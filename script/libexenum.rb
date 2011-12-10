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

  def deep_update(obj)
    rec_merge(obj,self)
    self
  end

  private
  def rec_merge(a,b)
    case a
    when Hash
      b= b.is_a?(Hash) ? b : {}
      a.keys.each{|i| b[i]=rec_merge(a[i],b[i])}
    when Array
      b= b.is_a?(Array) ? b : []
      a.size.times{|i| b[i]=rec_merge(a[i],b[i])}
    else
      b=a||b
    end
    b
  end
end

class ExHash < Hash
  include ExEnum
end

class ExArray < Array
  include ExEnum
end
