#!/usr/bin/ruby
require "libmsg"
require "libmodfile"
# Status to View (String with attributes)
class View < Hash
  include ModFile
  def initialize(id=nil,db=nil)
    @v=Msg::Ver.new("view",6)
    @db=db
    if id
      @type="json/status_#{id}"
      self['id']=id
    end
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
