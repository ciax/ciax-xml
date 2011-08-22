#!/usr/bin/ruby
require "libverbose"
# Status to View (String with attributes)
class View < Hash
  def initialize(stat)
    @stat=stat
    hash=self['list']={}
    stat.each{|k,v|
      case k
      when 'id','frame','class'
        self[k]=v
      else
        hash[k]={'val'=>v}
      end
    }
  end

  def opt(opt,db=nil)
    @db=db if db
    add_label if opt.include?('l')
    add_arrange if opt.include?('a')
    init_sym if opt.include?('s')
    self
  end

  def upd
    self['list'].each{|k,v|
      v['val']=@stat[k]
    }
    @sdb.convert(self) if @sdb
    self
  end

  def to_s
    Verbose.view_struct(self)
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
    if @db
      require "libsymbols"
      @sdb=Symbols.new(@db)
    end
    self
  end
end
