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
        @base="http://"+host+base
      else
        @base=VarDir+base
      end
      self['id']=id
      @fname=@base+'.json'
    end
  end

  def settag(tag)
    @fname=@base+"_#{tag}.json" if @base
  end

  def load
    if @fname
      if File.exist?(@fname)
        open(@fname){|f|
          str=f.read
          if str.empty?
            Msg.warn(" -- json file is empty")
          else
            deep_update(JSON.load(str))
          end
        }
      else
        Msg.warn("  -- no json file")
      end
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
end
