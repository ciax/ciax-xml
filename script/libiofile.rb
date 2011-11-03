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
      open(@fname){|f| deep_update(JSON.load(f.read)) }
    else
      deep_update(JSON.load(gets(nil))
    end
    self
  end

  def save(data=nil)
    if @fname
      open(@fname,'w'){|f| f << JSON.dump(data||to_h)}
    else
      puts JSON.dump(data||to_h)
    end
    self
  end
end
