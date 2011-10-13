#!/usr/bin/ruby
require "libmsg"
require "libexhash"

class Uri < ExHash
  def initialize(type,id=nil,host=nil)
    @v=Msg::Ver.new('uri',6)
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
      update_j(gets)
    end
    self
  end

  def save
    open(@uri,'w'){|f| f << to_j}
    self
  end
end
