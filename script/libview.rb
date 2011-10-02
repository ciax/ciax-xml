#!/usr/bin/ruby
require "libmsg"
require "libstat"
# Status to View (String with attributes)
class View < Stat
  def initialize(id=nil,db=nil)
    super('view',id)
    @db=db
    if @db && @db.key?(:symbol)
      require "libsymdb"
      @sdb=SymDb.new.add('all')
      @sdb.add(@db['table']) if @db['table']
    end
    self['stat']={}
  end

  def upd
    @sdb.convert(self,@db[:symbol]) if @sdb
    self
  end
end
