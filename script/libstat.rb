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

  def save_all
    @fd.save_stat(Hash[self])
  end

  def save(stat,tag='default')
    @fd.save_stat(stat,tag)
  end

  def sub_stat(str)
    return str unless /\${/ === str
    @v.msg(1){"Substitute from [#{str}]"}
    begin
      # output csv if array
      str=str.gsub(/\$\{(.+)\}/) {
        [*acc_stat($1)].join(',')
      }
      raise if str == ''
      str
    ensure
      @v.msg(-1){"Substitute to [#{str}]"}
    end
  end

  def set_stat(key,val)
    h=acc_stat(key)
    h.replace(eval(sub_stat(val)).to_s) if val
    h
  end

  def acc_stat(key) # ${key1:key2:idx} => hash[key1][key2][idx]
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
