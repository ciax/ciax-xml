#!/usr/bin/ruby
require "libcircular"
class Arrange
  def initialize(db)
    raise "Arrange have to be given Db" unless db.kind_of?(Db)
    return unless db.status.key?(:group)
    @group=[['time']]+db.status[:group]
  end

  def convert(view)
    view['group']=@group if @group
    self
  end
end
