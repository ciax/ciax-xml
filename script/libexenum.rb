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
  # a will be merged to b (b is changed)
  def rec_merge(a,b)
    each_idx(a){|i,cls|
      b=cls.new unless cls === b
      b[i]=rec_merge(a[i],b[i])
    } || b=a||b
    b
  end

  def rec_proc(db)
    each_idx(db){|i|
      rec_proc(db[i]){|i| yield i}
    }
    yield db
  end

  def each_idx(obj)
    case obj
    when Hash
      obj.each{|k,v| yield k,Hash}
    when Array
      obj.each_index{|i| yield i,Array}
    else
      nil
    end
  end
end

class ExHash < Hash
  include ExEnum
end

class ExArray < Array
  include ExEnum
end

if __FILE__ == $0
  a=ExHash.new
  a[:a] = []
  a[:b] = {}
  a[:c] = {:m => {:n => {:l => '*'}}}
  a[:d] = {:x => 1}
  puts "a="
  p a
  b=ExHash.new
  b[:a] = [1]
  b[:b]={:i => 'i'}
  b[:d] = {:y => 2}
  puts "b="
  p b
  puts "b <- a(over write)"
  puts
  b.deep_update a
  p b
end
