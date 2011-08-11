#!/usr/bin/ruby
# Status to View (String with attributes)
require "libview"
require "libprint"
class ViewOpt < View
  def initialize(db,hash)
    @db=db
    super(hash)
  end

  def opt(opt)
    add_label if opt.include?('l')
    add_arrange if opt.include?('a')
    init_sym if opt.include?('s')
    self
  end

  def upd
    super
    @sdb.convert(self) if @sdb
    self
  end

  private
  def add_label
    if @db
      self['label']=Hash[@db[:status][:label]]
    end
    self
  end

  def add_arrange
    if @db && @db[:status].key?(:group)
      self['group']=@db[:status][:group]
    end
    self
  end

  def init_sym
    if @db
      require "libsymdb"
      require "libsymbols"
      @db[:tables].update(SymDb.new)
      @sdb=Symbols.new(@db)
    end
    self
  end
end
