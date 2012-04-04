#!/usr/bin/ruby
require "libmsg"
require "json"
require "libexenum"

# Read/Write JSON file
class IoFile < ExHash
  # ID : Host : Type
  # _  :  *   : StdIO
  # v  :  _   : File
  # v  :  v   : URL
  def initialize(type,id=nil,host=nil)
    @v=Msg::Ver.new(self,6)
    if id
      @base="#{type}_#{id}"
      @suffix='.json'
      if host
        require "open-uri"
        @prefix="http://"+host+"/json/"
        @type='url'
        @v.msg{"Type:URL"}
      else
        @prefix=VarDir+"/json/"
        @type='file'
        @v.msg{"Type:FileIO"}
      end
      self['id']=id
    else
      @v.msg{"Type:StdIO"}
    end
  end

  def settag(tag)
    @suffix="_#{tag}.json" if @base
    self
  end

  def load
    fname=@prefix+@base+@suffix
    case @type
    when 'file'
      if File.exist?(fname)
        load_uri(fname)
      else
        Msg.warn("  -- no json file (#{fname})")
      end
    when 'url'
      load_uri(fname)
    else
      deep_update(JSON.load(gets(nil)))
    end
    self
  end

  def to_j
    JSON.dump(to_hash)
  end

  private
  def load_uri(uri)
    @v.msg{"Loading URL #{uri}"}
    open(uri){|f|
      str=f.read
      if str.empty?
        Msg.warn(" -- json file is empty")
      else
        deep_update(JSON.load(str))
      end
    }
  end
end

module Writable
  def save(data=nil)
    case @type
    when 'file'
      @v.msg{"Saving #{@base+@suffix} file"}
      open(@prefix+@base+@suffix,'w'){|f| f << JSON.dump(data||to_hash)}
    else
      puts JSON.dump(data||to_hash)
    end
    self
  end
end
