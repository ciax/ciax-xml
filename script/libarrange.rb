#!/usr/bin/ruby
require "libcircular"
class Arrange < Hash
  def initialize(hash)
    raise "Arrange have to be given Db" unless hash.kind_of?(Db)
    @c=Circular.new(5)
    update(hash.status[:row]||{})
    update({'time'=>0,'class'=>0,'frame'=>0})
  end

  def convert(view)
    list=[]
    prev=-1
    view['list'].each{|hash|
      id=hash['id']
      if key?(id)
        hash['row']=self[id]
        if prev != hash['row']
          @c.reset
          prev=hash['row']
        end
      else
        hash['row']=@c.row
      end
      hash['col']=@c.col
      @c.next
      list << hash
    }
    view['list']=list.sort_by{|h| "%02d%02d" % [h['row'],h['col']] }
    self
  end
end
