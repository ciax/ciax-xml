#!/usr/bin/ruby
require 'libverbose'
require 'libstat'
require 'libiofile'

class IoStat < Stat
  def initialize(id,fname)
    @v=Verbose.new("stat",5)
    raise SelectID," No ID" unless id
    fname+="_#{id}"
    begin
      @fd=IoFile.new(fname)
      load
    rescue
      @v.warn("----- No #{fname}.json")
    end
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
end
