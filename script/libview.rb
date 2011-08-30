#!/usr/bin/ruby
require "libverbose"
require "libmodio"
# Status to View (String with attributes)
class View < Hash
  include ModIo
  def initialize(id=nil)
    @v=Verbose.new("view",6)
    @type="json/status_#{id}" if id
    self['stat']={}
  end

  def opt(opt,db=nil)
    @db=db if db
    add_label if opt.include?('l')
    add_arrange if opt.include?('a')
    init_sym if opt.include?('s')
    self
  end

  def upd
    @sdb.convert(self,@db[:symbol]) if @sdb
    self
  end

  private
  def add_label
    if @db && @db.key?(:label)
      self['label']=Hash[@db[:label]]
    end
    self
  end

  def add_arrange
    if @db && @db.key?(:group)
      self['group']=@db[:group]
    end
    self
  end

  def init_sym
    if @db && @db.key?(:symbol)
      require "libsymdb"
      @sdb=SymDb.new.update(SymDb.new(self['app_type']))
    end
    self
  end
end
