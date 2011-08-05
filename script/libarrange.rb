#!/usr/bin/ruby
require "libcircular"
class Arrange
  def initialize(db)
    raise "Arrange have to be given Db" unless db.kind_of?(Db)
    @c=Circular.new(5)
    @group=db.status[:group].update({'time' => 0})
    @title=db.status[:title]
    @row=db.status[:row]||{}
    @row.update({'time'=>0,'class'=>0,'frame'=>0})
  end

  def convert(view)
    view['title']=@title
    prev=-1
    view['list'].each{|id,hash|
      hash['grp']=@group[id]
      if @row.key?(id)
        hash['row']=@row[id]
        if prev != hash['row']
          @c.roundup
          prev=hash['row']
        end
      else
        hash['row']=@c.row
      end
      hash['col']=@c.col
      @c.next
    }
    view['col']=@c.max
    self
  end
end
