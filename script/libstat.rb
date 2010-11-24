#!/usr/bin/ruby
require 'libiofile'
require 'libverbose'
class Stat < Hash
  def initialize(id,fname)
    @v=Verbose.new("Stat")
    raise " No ID" unless id
    self['id']=id
    fname+="_#{id}"
    begin
      @fd=IoFile.new(fname)
      load
    rescue
      warn "----- No #{fname}.json"
    end
  end

  def load(tag=nil)
    update(@fd.load_stat(tag))
  end

  def save(tag=nil,keys=nil)
    if keys
      stat={}
      keys.each{|k|
        stat[k]=self[k] if key?(k)
      }
      @fd.save_stat(stat,tag)
    else
      @fd.save_stat(Hash[self])
    end
  end

  def subst(str)
    return str unless /\$\{/ === str
    @v.msg(1){"Substitute from [#{str}]"}
    begin
      # output csv if array
      str=str.gsub(/\$\{(.+)\}/) {
        [*get($1)].join(',')
      }
      raise if str == ''
      str
    ensure
      @v.msg(-1){"Substitute to [#{str}]"}
    end
  end

  def set(key,val)
    h=get(key)
    h.replace(eval(subst(val)).to_s) if val
    h
  end

  def get(key=nil) # ${key1:key2:idx} => hash[key1][key2][idx]
    return Hash[self] unless key
    key.split(':').inject(self){|h,i|
      begin
        i=eval(i) if Array === h
      rescue SyntaxError
        raise("#{i} is not number")
      end
      @v.msg{"Type[#{h.class}] Name[#{i}]"}
      h[i]||raise("No such Value [#{i}]")
    }
  end
end
