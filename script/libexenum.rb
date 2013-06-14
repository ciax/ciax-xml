#!/usr/bin/ruby
require 'libmsg'
require 'json'
#Extened Hash
module CIAX
  module ExEnum
    include Msg::Ver
    def to_s
      Msg.view_struct(self)
    end

    def to_j
      case self
      when Array
        JSON.dump(to_a)
      when Hash
        JSON.dump(to_hash)
      end
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
    def deep_update(ope,depth=nil)
      rec_merge(ope,self,depth)
      self
    end

    def load(json_str=nil)
      data=json_str||gets(nil)||Msg.abort("No data in file(#{ARGV})")
      deep_update(JSON.load(data))
    end

    private
    # r(operand) will be merged to w (w is changed)
    def rec_merge(r,w,d)
      d-=1 if d
      each_idx(r,w){|i,cls|
        w=cls.new unless cls === w
        if d && d < 1
          w[i]=r[i]
        else
          w[i]=rec_merge(r[i],w[i],d)
        end
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

  class ExArray < Array
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
    puts
    r=ExHash.new
    r[:c] = {:m => 'm', :n => {:x => 'x'}}
    r[:d] = [1]
    r[:e] = 'e'
    print "r="
    p r
    w=ExHash.new
    w[:c]= {:i => 'i', :n => {:y => 'y'}}
    w[:d] = [2,3]
    w[:f] = 'f'
    w1=w.deep_copy
    w2=w.deep_copy
    print "w="
    p w
    w.deep_update r
    puts "w <- r(over write)"
    p w
    puts
    w2.deep_update(r,2)
    puts "w <- r(over write) Level 2"
    p w2
    puts
    w1.deep_update(r,1)
    puts "w <- r(over write) Level 1"
    p w1
  end
end
