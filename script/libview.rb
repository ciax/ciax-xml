#!/usr/bin/ruby
# Status to View (String with attributes)
require "libprint"
class View < Hash
  def initialize(stat={},odb=nil)
    @odb=odb
    if stat.key?('list')
      update(stat)
    else
      @stat=stat
      ary=self['list']=[]
      stat.each{|k,v|
        case k
        when 'id','frame','class'
          self[k]=v
        else
          ary << {'id'=>k, 'val'=>v}
        end
      }
    end
  end

  def opt(opt)
    add_label if opt.include?('l')
    add_arrange if opt.include?('a')
    init_sym if opt.include?('s')
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

  # Filterling values by env value of VAL
  # VAL=a:b:c -> grep "a|b|c"
  def to_s
    list=[]
    each{|k,v|
      case k
      when 'list'
        if pick=ENV['VAL']
          exp=pick.tr(':','|')
          list << v.select{|line| /#{exp}/ === line['id']}
        else
          list << v
        end
      else
        list << "#{k} = #{v}"
      end
    }
    if @prt
      @prt.print(self)
    else
      list.join("\n")
    end
  end
end
