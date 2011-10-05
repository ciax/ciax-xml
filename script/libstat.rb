#!/usr/bin/ruby
require 'libmsg'
require 'libexhash'

class Stat < ExHash
  def initialize(type,id=nil)
    @v=Msg::Ver.new(type,6)
    @type=type
    if id
      @base=VarDir+"/json/#{type}_#{id}"
      self['id']=id
    end
  end

  # N/A unless id
  def load(tag=nil)
    Msg.err("No File Name")  unless @base
    tbase=[@base,tag].compact.join('_')
    @v.msg{"Status Loading for [#{tbase}]"}
    fname="#{tbase}.json"
    if FileTest.exist?(fname)
      update_j(IO.read(fname))
    elsif tag
      raise SelectID,list_stat
    else
      Msg.warn("----- No #{tbase}.json")
    end
    self
  end

  def save(tag=nil,hash=self)
    Msg.err("No File Name")  unless @base
    tbase=[@base,tag].compact.join('_')
    fname="#{tbase}.json"
    @v.msg{"Status Saving for [#{tbase}]"}
    open(fname,'w') {|f| f << ExHash[hash].to_j }
    mklink(fname,tag)
    self
  end

  private
  def mklink(fname,tag)
    return unless tag
    sname="#{@base}_latest.json"
    File.unlink(sname) if File.exist?(sname)
    File.symlink(fname,sname)
    @v.msg{"Symboliclink to [#{sname}]"}
  end

  def list_stat
    list=[]
    Dir.glob("#{@base}_*.json"){|f|
      tag=f.slice(/#{@base}_(.+)\.json/,1)
      list << tag
    }
    "Tag=#{list}"
  end
end
