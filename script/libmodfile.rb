#!/usr/bin/ruby
require 'json'

module ModFile
  VarDir="#{ENV['HOME']}/.var"
  attr_writer :type,:v

  def to_j(hash=nil)
    JSON.dump(hash||Hash[self])
  end

  def update_j(str)
    if str && !str.empty?
      update(JSON.load(str))
    else
      Msg.warn "No status in File"
    end
    self
  end

  def load(tag=nil)
    raise "No Cache File Name"  unless @type
    base=[@type,tag].compact.join('_')
    @v.msg{"Status Loading for [#{base}]"}
    fname=VarDir+"/#{base}.json"
    if FileTest.exist?(fname)
      update_j(IO.read(fname))
    elsif tag
      raise SelectID,list_stat
    else
      Msg.warn("----- No #{base}.json")
    end
    self
  end

  def save(tag=nil,hash=nil)
    raise "No Cache File Name"  unless @type
    base=[@type,tag].compact.join('_')
    fname=VarDir+"/#{base}.json"
    json=to_j(hash)
    @v.msg{"Status Saving for [#{base}]"}
    open(fname,'w') {|f| f << json }
    mklink(fname,tag)
    self
  end

  private
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
