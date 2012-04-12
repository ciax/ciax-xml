#!/usr/bin/ruby
require "libmsg"
require "json"
require "open-uri"
require "libexenum"

# Should be included ExHash object
# Read/Write JSON file
# Need self['type']
module IoUrl
  def init(id,host='')
    self['id']=id
    @dir="/json/"
    @base=self['type']+"_"+id
    @suffix='.json'
    @prefix="http://"+host
    self
  end

  def settag(tag)
    @suffix="_#{tag}.json"
    self
  end

  def load
    open(fname){|f|
      str=f.read
      if str.empty?
        Msg.warn(" -- json file is empty")
      else
        deep_update(JSON.load(str))
      end
    }
  end

  private
  def fname
    @prefix+@dir+@base+@suffix
  end
end

module IoFile
  include IoUrl
  def init(id)
    super(id)
    @prefix=VarDir
    self
  end

  def load
    if File.exist?(fname)
      super
    else
      Msg.warn("  -- no json file (#{fname})")
    end
    self
  end

  def save(data=nil)
    open(fname,'w'){|f| f << JSON.dump(data||to_hash)}
    self
  end
end
