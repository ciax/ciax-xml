#!/usr/bin/ruby
require "libmsg"
require "json"
require "open-uri"
require "libexenum"

# Should be included ExHash object
# Read/Write JSON file
# Need self['type']
module InFile
  def self.extended(obj)
    Msg.type?(obj,ExHash)
  end

  def init(id)
    self['id']=id
    @dir="/json/"
    @base=self['type']+"_"+id
    @suffix='.json'
    @prefix=VarDir
    self
  end

  def load
    begin
      open(fname){|f|
        str=f.read
        if str.empty?
          Msg.warn(" -- json file is empty")
        else
          deep_update(JSON.load(str))
        end
      }
    rescue
      Msg.warn("  -- no json file (#{fname})")
    end
    self
  end

  def settag(tag)
    @suffix="_#{tag}.json"
    self
  end

  private
  def fname
    @prefix+@dir+@base+@suffix
  end
end

module InUrl
  include InFile
  def init(id,host='')
    super(id)
    @prefix="http://"+host
    self
  end
end

module IoFile
  include InFile
  def save(data=nil)
    open(fname,'w'){|f| f << JSON.dump(data||to_hash)}
    self
  end
end
