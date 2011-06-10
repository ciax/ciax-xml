#!/usr/bin/ruby
require "libcircular"
class Group < Hash
  def initialize(hash)
    raise "Group have to be given Db" unless hash.kind_of?(Db)
    @c=Circular.new(4)
    self['time'] = '0'
    update(hash.status[:group]||{})
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
    view['list']=list.sort_by{|h| h['group']+h['id']}
    self
  end
end
