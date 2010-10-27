#!/usr/bin/ruby
require 'libiofile'
require 'libverbose'
class Stat < Hash
  def initialize(id,fname)
    @v=Verbose.new
    self['id']=id
    fname+="_#{id}"
    begin
      @fd=IoFile.new(fname)
      load
    rescue
      warn "----- Create #{fname}.mar"
    end
  end

  def load(tag=nil)
    update(@fd.load_stat(tag))
  end

  def save(stat=nil,tag='default')
    if stat
      @fd.save_stat(stat,tag)
    else
      @fd.save_stat(Hash[self])
    end
  end

  def subst(str)
    return str unless /\${/ === str
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

  def get(key) # ${key1:key2:idx} => hash[key1][key2][idx]
    h=self
    return h unless key
    key.split(':').each {|i|
      @v.msg{"Stat:Type[#{h.class}] Name[#{i}]"}
      begin
        i=eval(i) if Array === h
      rescue SyntaxError
        raise("#{i} is not number")
      end
      h=h[i]||raise("No such Value [#{i}]")
    }
    h
  end
end
