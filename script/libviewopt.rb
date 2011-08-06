#!/usr/bin/ruby
# Status to View (String with attributes)
require "libview"
require "libprint"
class ViewOpt < View
  def initialize(odb)
    @odb=odb
    super(['time']+odb.status[:cdb].keys)
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
    if @odb
      require "liblabel"
      Label.new(@odb).convert(self)
    end
    self
  end

  def add_arrange
    if @odb
      require "libarrange"
      Arrange.new(@odb).convert(self)
    end
    self
  end

  def init_sym
    if @odb
      require "libsymdb"
      require "libsymbols"
      @odb.tables.update(SymDb.new)
      @sdb=Symbols.new(@odb)
    end
    self
  end

end
