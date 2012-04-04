#!/usr/bin/ruby
require 'libmsg'
#Extened Hash
module ExEnum
  def to_s
    Msg.view_struct(self)
  end

  def attr_update(obj)
    each_idx(obj){|i|
      self[i]=obj[i] if Comparable === obj[i]
    }
    self
  end

  def deep_copy
    Marshal.load(Marshal.dump(self))
  end

  # Freeze one level deepth or more
  def deep_freeze
    rec_proc(self){|i|
      i.freeze
    }
    self
  end

  # Merge self to obj
  def deep_update(obj)
    rec_merge(obj,self)
    self
  end

  private
  # r will be merged to w (w is changed)
  def rec_merge(r,w)
    each_idx(r){|i,cls|
      w=cls.new unless cls === w
      w[i]=rec_merge(r[i],w[i])
      w
    }
  end

  def rec_proc(db)
    each_idx(db){|i|
      rec_proc(db[i]){|d| yield d}
    }
    yield db
  end

  def each_idx(obj)
    res=obj
    case obj
    when Hash
      obj.each_key{|k| res=yield k,Hash}
    when Array
      obj.each_index{|i| res=yield i,Array}
    end
    res
  end
end

class ExHash < Hash
  include ExEnum
end

class ExArray < Array
  include ExEnum
end

if __FILE__ == $0
  w=ExHash.new
  w[:a]=1
  w[:c] = []
  print "w="
  p w
  r=ExHash.new
  r[:b]=2
  r[:d] = {}
  print "r="
  p r
  w.deep_update r
  puts "w <- r(over write)"
  p w
  puts
  r=ExHash.new
  r[:c] = {:m => 'm'}
  r[:d] = [1]
  print "r="
  p r
  w=ExHash.new
  w[:c]= {:i => 'i'}
  w[:d] = [2,3]
  print "w="
  p w
  w.deep_update r
  puts "w <- r(over write)"
  p w
end
