#!/usr/bin/ruby
require 'json'

module ModIo
  VarDir="#{ENV['HOME']}/.var"
  attr_writer :type,:v

  def to_s
    Verbose.view_struct(self)
  end

  def to_j(*klist)
    if klist.empty?
      hash=Hash[self]
    else
      hash=pick(klist)
    end
    JSON.dump(hash)
  end

  def update_j(str)
    update(JSON.load(str))
  end

  def load(tag=nil)
    raise "No File Name"  unless @type
    base=[@type,tag].compact.join('_')
    @v.msg{"Status Loading for [#{base}]"}
    fname=VarDir+"/#{base}.json"
    if FileTest.exist?(fname)
      stat=JSON.load(IO.read(fname))
      raise "No status in File" unless stat
      update(stat)
    elsif tag
      raise SelectID,list_stat
    else
      @v.warn("----- No #{base}.json")
    end
    self
  end

  def save(tag=nil,keylist=nil)
    raise "No File Name"  unless @type
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


