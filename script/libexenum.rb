#!/usr/bin/ruby
require 'libmsg'
require 'json'
#Extened Hash
module ExEnum
  def to_s
    Msg.view_struct(self)
  end

  def to_j
    JSON.dump(to_hash)
  end

  # Show branch (omit lower tree of Hash/Array with sym key)
  def path(ary=[])
    enum=ary.inject(self){|prev,a|
      case prev
      when Array
        prev[a.to_i]
      when Hash
        prev[a.to_sym]||prev[a.to_s]
      end
    }||Msg.abort("No such key")
    data=enum.dup
    data.each{|k,v|
      data[k]=v.class.to_s if Enumerable === v
    } if Hash === data
    Msg.view_struct(data)
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

  # Merge self to ope
  def deep_update(ope)
    rec_merge(ope,self)
    self
  end

  def load(json_str=nil)
    deep_update(JSON.load(json_str||gets(nil)))
  end

  private
  # r(operand) will be merged to w (w is changed)
  def rec_merge(r,w)
    each_idx(r,w){|i,cls|
      w=cls.new unless cls === w
      w[i]=rec_merge(r[i],w[i])
    }
  end

  def rec_proc(db)
    each_idx(db){|i|
      rec_proc(db[i]){|d| yield d}
    }
    yield db
  end

  def each_idx(ope,res=nil)
    case ope
    when Hash
      ope.each_key{|k| yield k,Hash}
      res||ope.dup
    when Array
      ope.each_index{|i| yield i,Array}
      res||ope.dup
    when String
      ope.dup
    else
      ope
    end
  end
end

class ExHash < Hash
  include ExEnum
end

if __FILE__ == $0
  w=ExHash.new
  w[:a]=1
  w[:c] = []
  w[:e] = {:x => 1}
  print "w="
  p w
  r=ExHash.new
  r[:b]=2
  r[:d] = {}
  r[:f] = [1]
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
