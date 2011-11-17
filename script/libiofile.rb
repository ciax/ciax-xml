#!/usr/bin/ruby
require "libmsg"
require "json"
require "libmodexh"

class IoFile < Hash
  include ModExh
  def initialize(type,id=nil,host=nil)
    @v=Msg::Ver.new(type,6)
    if id
      base="/json/#{type}_#{id}"
      if host
        require "open-uri"
        @url="http://"+host+base+'.json'
      else
        @base=VarDir+base
        @fname=@base+'.json'
      end
      self['id']=id
    end
  end

  def settag(tag)
    @fname=@base+"_#{tag}.json" if @base
  end

  def load
    if @fname
      if File.exist?(@fname)
        load_uri(@fname)
      else
        Msg.warn("  -- no json file")
      end
    elsif @url
      load_uri(@url)
    else
      deep_update(JSON.load(gets(nil)))
    end
    self
  end

  def save(data=nil)
    if @fname
      open(@fname,'w'){|f| f << JSON.dump(data||to_hash)}
    else
      puts JSON.dump(data||to_hash)
    end
    self
  end

  def to_j
    JSON.dump(to_hash)
  end

  private
  def load_uri(uri)
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
