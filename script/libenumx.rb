#!/usr/bin/ruby
require 'libview'
require 'json'
#Extened Hash
module CIAX
  module Enumx
    include ViewStruct
    def self.extended(obj)
      raise("Not Enumerable") unless obj.is_a? Enumerable
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
        if /@/ === a
          prev.instance_variable_get(a)
        else
          case prev
          when Array
            prev[a.to_i]
          when Hash
            prev[a.to_sym]||prev[a.to_s]
          end
        end
      }||Msg.abort("No such key")
      branch=enum.dup.extend(ViewStruct)
      if Hash === branch
        branch.each{|k,v|
          branch[k]=v.class.to_s if Enumerable === v
        }
      end
      branch.instance_variables.each{|n|
        v=branch.instance_variable_get(n)
        branch.instance_variable_set(n,v.class.to_s) if Enumerable === v
      }
      branch.view_struct(true,true)
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
      verbose("Merging, later is overridden by formar",ope,self)
      self
    end

    def read(json_str=nil)
      deep_update(j2h(json_str))
    end

    def to_s
      view_struct
    end

    private
    def j2h(json_str=nil)
      JSON.load(json_str||gets(nil)||Msg.abort("No data in file(#{ARGV})"))
    end

    # r(operand) will be merged to w (w is changed)
    def rec_merge(r,w,d)
      d-=1 if d
      each_idx(r,w){|i,cls|
        w=cls.new unless cls === w
        if d && d < 1
          verbose("Merging #{i}")
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

  class Hashx < Hash
    include Enumx
    attr_accessor :vmode
    def initialize(hash={})
      update(hash)
      @vmode="v" # v|r|j
      ['v','r','j'].each{|k|
        @vmode=k if $opt[k]
      } if $opt
    end

    def to_s
      @vmode == 'j' ? to_j : super
    end

    # Make empty copy
    def skeleton
      hash=Hashx.new
      keys.each{|i|
        hash[i]=nil
      }
      hash
    end
  end

  class Arrayx < Array
    include Enumx
    #sary: array of the element numbers [a,b,c,..]
    def skeleton(sary)
      return '' if sary.empty?
      dary=[]
      sary[0].to_i.times{|i|
        dary[i]=skeleton(sary[1..-1])
      }
      dary
    end
  end
end
