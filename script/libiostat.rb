#!/usr/bin/ruby
require 'libverbose'
require 'libstat'

class IoStat < Stat
  VarDir="#{ENV['HOME']}/.var"
  def initialize(id,type)
    @v=Verbose.new("stat",5)
    raise SelectID," No ID" unless id
    @type=type+"_#{id}"
    begin
      load
    rescue
      @v.warn("----- No #{@type}.json")
    end
  end

  def load(tag=nil)
    base=[@type,tag].compact.join('_')
    @v.msg{"Status Loading for [#{base}]"}
    fname=VarDir+"/#{base}.json"
    raise SelectID,list_stat unless !tag || FileTest.exist?(fname)
    stat=JSON.load(IO.read(fname))
    raise "No status in File" unless stat
    update(stat)
  end

  def save(tag=nil,keylist=nil)
    base=[@type,tag].compact.join('_')
    fname=VarDir+"/#{base}.json"
    if keylist
      json=JSON.dump(pick(keylist))
    else
      json=to_j
    end
    open(fname,'w') {|f|
      @v.msg{"Status Saving for [#{base}]"}
      f << json
    }
    mklink(fname,tag)
    self
  end

  private
  def pick(ary)
    stat={}
    ary.each{|k|
      stat[k]=self[k] if key?(k)
    }
    stat
  end

  def mklink(fname,tag)
    return unless tag
    sbase=[@type,'latest'].compact.join('_')
    sname=VarDir+"/#{sbase}.json"
    File.unlink(sname) if File.exist?(sname)
    File.symlink(fname,sname)
    @v.msg{"Symboliclink to [#{sbase}]"}
  end

  def list_stat
    list=[]
    Dir.glob(VarDir+"/#{@type}_*.json"){|f|
      tag=f.slice(/#{@type}_(.+)\.json/,1)
      list << tag
    }
    "Tag=#{list}"
  end
end
