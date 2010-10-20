#!/usr/bin/ruby
require 'libverbose'
class Stat < Hash
  def initialize(fname)
    @v=Verbose.new
    begin
      @fd=IoFile.new(fname)
      update(@fd.load_stat)
    rescue
      warn "----- Create #{fname}.mar"
    end
  end

  def load(tag='default')
    update(@fd.load_stat(tag))
  end

  def save_all
    @fd.save_stat({}.update(self))
  end

  def save(stat,tag='default')
    @fd.save_stat(stat,tag)
  end

  def sub_stat(str)
    return str unless /\${/ === str
    @v.msg(1){"Substitute from [#{str}]"}
    begin
      # Sub ${key1:key2:idx} => hash[key1][key2][idx]
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

  def acc_stat(key)
    h=self
    return h unless key
    key.split(':').each {|i|
      @v.msg{"Stat:Type[#{h.class}] Name[#{i}]"}
      i=eval(i) if Array === h
      h=h[i]||raise("No such Value [#{i}]")
    }
    h
  end
end
