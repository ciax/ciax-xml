#!/usr/bin/ruby
require "libcircular"
class Group < Hash
  def initialize(hash)
    @c=Circular.new(4)
    self['time'] = '0'
    update(hash||{})
  end

  def convert(view)
    list=[]
    view['list'].each{|hash|
      id=hash['id']
      if key?(id)
        hash['group']=self[id]
      else
        hash['group']="AN#{@c.next.row}"
      end
        list << hash
    }
    view['list']=list.sort_by{|h| h['group']}
    self
  end
end
