#!/usr/bin/ruby
# Status to View (String with attributes)
require "libprint"
class View < Hash
  def initialize(stat={})
    if stat.key?('list')
      update(stat)
    else
      @stat=stat
      ary=self['list']=[]
      stat.each{|k,v|
        case k
        when 'id','frame','class'
          self[k]=v
        end
        ary << {'id'=>k, 'val'=>v}
      }
      upd
    end
  end

  def add(odb,opt)
    add_label(odb) if opt.include?('l')
    add_arrange(odb) if opt.include?('a')
    init_sym(odb) if opt.include?('s')
    @prt=Print.new if opt.include?('p')
    self
  end

  def upd
    self['list'].each{|h|
      h['val']=@stat[h['id']]
    }
    @sdb.convert(self) if @sdb
    self
  end

  def add_label(odb=@odb)
    if @odb=odb
      require "liblabel"
      Label.new(odb).convert(self)
    end
    self
  end

  def add_arrange(odb=@odb)
    if @odb=odb
      require "libarrange"
      Arrange.new(odb).convert(self)
    end
    self
  end

  def init_sym(odb=@odb)
    if @odb=odb
      require "libsymdb"
      require "libsymtbls"
      sym=SymDb.new.update(odb.tables)
      @sdb=SymTbls.new(sym,odb)
    end
    self
  end

  # Filterling values by env value of VAL
  # VAL=a:b:c -> grep "a|b|c"
  def to_s
    header=[]
    ['id','frame','class'].each{|s|
      header << "#{s} = #{self[s]}" if key?(s)
    }
    if pick=ENV['VAL']
      exp=pick.tr(':','|')
      list=self['list'].select{|line| /#{exp}/ === line['id']}
    else
      list=self['list']
    end
    if @prt
      @prt.print(self)
    else
      (header+list).join("\n")
    end
  end
end
