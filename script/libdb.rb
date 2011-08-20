#!/usr/bin/ruby
require "libverbose"
require "libxmldoc"
require "libcache"

class Db < Cache
  def initialize(type,id)
    super(type,id){
      @doc=XmlDoc.new(type,id)
      @v=Verbose.new("#{type}/#{@doc['id']}",2)
      update(@doc)
      yield
      self
    }
  end
end
