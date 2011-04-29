#!/usr/bin/ruby
require 'libiofile'
require 'libverbose'
class Stat < Hash
  def initialize(id,fname)
    @v=Verbose.new("stat",6)
    raise SelectID," No ID" unless id
    self['id']=id
    fname+="_#{id}"
    begin
      @fd=IoFile.new(fname)
      load
    rescue
      warn "----- No #{fname}.json"
    end
  end

  def to_h
    Hash[self]
  end

  def load(tag=nil)
    update(@fd.load_stat(tag))
    self
  end

  def save(tag=nil,keys=nil)
    if keys
      stat={}
      keys.each{|k|
        stat[k]=self[k] if key?(k)
      }
      @fd.save_stat(stat,tag)
    else
      @fd.save_stat(to_h)
    end
    self
  end

  def subst(str)
    return str unless /\$\{/ === str
    @v.msg(1){"Substitute from [#{str}]"}
    begin
      # output csv if array
      str=str.gsub(/\$\{(.+)\}/) {
        ary=[*get($1)].map!{|i| eval(i)}
        raise("No value for subst [#{$1}]") if ary.empty?
        ary.join(',')
      }
      str
    ensure
      @v.msg(-1){"Substitute to [#{str}]"}
    end
  end

  # For multiple dimention (content should be numerical)
  def get(key) # ${key1:key2:idx} => hash[key1][key2][idx]
    raise "No Key" unless key
    vname=[]
    key.split(':').inject(self){|h,i|
      begin
        i=eval(i) if Array === h
      rescue SyntaxError
        raise("#{i} is not number")
      end
      vname << i
      @v.msg{"Type[#{h.class}] Name[#{i}]"}
      @v.msg{"Content[#{h[i]}]"}
      h[i]||raise("No such Value [#{vname.join(':')}]")
    }
  end

  def set(key,val)
    get(key).replace(subst(val).to_s)
    self
  end
end
