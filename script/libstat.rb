#!/usr/bin/ruby
require 'libmsg'
require 'libexhash'

class Stat < ExHash
  def initialize(type,id)
    @v=Msg::Ver.new(type,6)
    @type=type
    @base=VarDir+"/json/#{type}_#{id}"
    self['id']=id
  end

  # N/A unless id
  def loadkey(tag=nil)
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

  def savekey(keylist,tag=nil)
    Msg.err("No File Name")  unless @base
    hash=ExHash.new
    keylist.each{|k|
      if key?(k)
        hash[k]=self[k]
      else
        Msg.warn("No such Key [#{k}]")
      end
    }
    if hash.empty?
      Msg.warn("No Keys")
    else
      tag||=Time.now.strftime('%y%m%d-%H%M%S')
      tbase=[@base,tag].compact.join('_')
      fname="#{tbase}.json"
      @v.msg{"Status Saving for [#{tbase}]"}
      open(fname,'w') {|f| f << hash.to_j }
      mklink(fname,tag)
    end
    self
  end

  def load
      update_j(IO.read(@base+".json"))
  end

  def save
    open(@base+".json",'w') {|f| f << self.to_j }
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
