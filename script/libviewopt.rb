#!/usr/bin/ruby
# Status to View (String with attributes)
require "libview"
require "libprint"
class ViewOpt < View
  def initialize(db,ids)
    @db=db
    super(['time']+ids)
  end

  def opt(opt)
    add_label if opt.include?('l')
    add_arrange if opt.include?('a')
    init_sym if opt.include?('s')
    self
  end

  def upd(stat)
    super
    @sdb.convert(self) if @sdb
    self
  end

  private
  def add_label
    if @db
      require "liblabel"
      Label.new(@db).convert(self)
    end
    self
  end

  def add_arrange
    if @db
      require "libarrange"
      Arrange.new(@db).convert(self)
    end
    self
  end

  def init_sym
    if @db
      require "libsymdb"
      require "libsymbols"
      @db.tables.update(SymDb.new)
      @sdb=Symbols.new(@db)
    end
    self
  end

end
