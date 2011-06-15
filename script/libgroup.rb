#!/usr/bin/ruby
require "libcircular"
class Group < Hash
  def initialize(hash)
    raise "Group have to be given Db" unless hash.kind_of?(Db)
    @c=Circular.new(4)
    @row=hash.status[:row]||{}
    @col=hash.status[:col]||{}
    @row['time']=@col['time'] = 0
  end

  def convert(view)
    list=[]
    view['list'].each{|hash|
      id=hash['id']
      if @row.key?(id)
        hash['col']=@col[id]
        hash['row']=@row[id]
      else
        hash['row']=@c.next.row
        hash['col']=@c.col
      end
        list << hash
    }
    view['list']=list.sort_by{|h| "%02d%02d" % [h['row'],h['col']] }
    self
  end
end
