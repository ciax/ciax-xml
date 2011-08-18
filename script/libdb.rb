#!/usr/bin/ruby
require "libverbose"
require "libxmldoc"

class Db < Hash
  def initialize(type,id)
    @doc=XmlDoc.new(type,id)
    @v=Verbose.new("#{type}/#{@doc['id']}",2)
    update(@doc)
    self[:command]={}
    self[:status]={:label => {'time' => 'TIMESTAMP' }}
  end

  def to_s
    Verbose.view_struct(self)
  end

  def cover(hash) # override with hash
    replace(rec_merge(self,hash))
  end

  private
  def rec_merge(me,oth)
    me.merge(oth){|k,s,h|
      Hash === h ? rec_merge(s,h) : s
    }
  end
end
