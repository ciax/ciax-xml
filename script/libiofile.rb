#!/usr/bin/ruby
require "libmsg"
require "libmodexh"

class IoFile < Hash
  include ModExh
  def initialize(type,id=nil,host=nil)
    @v=Msg::Ver.new(type,6)
    if id
      base="/json/#{type}_#{id}.json"
      if host
        require "open-uri"
        @uri="http://"+host+base
      else
        @uri=VarDir+base
      end
      self['id']=id
    end
  end

  def load
    if @uri
      open(@uri){|f| update_j(f.read) }
    else
      str=gets(nil)
      update_j(str) unless str.empty?
    end
    self
  end

  def save
    open(@uri,'w'){|f| f << to_j} if @uri
    self
  end
end
