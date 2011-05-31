#!/usr/bin/ruby
require "libcircular"
class Group < Hash
  def initialize(hash)
    @c=Circular.new(4)
    self['id'] = '0'
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
        @c.next
        hash['group']=@c.times
      end
        list << hash
    }
    view['list']=list
    self
  end
end
