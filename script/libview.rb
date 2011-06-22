#!/usr/bin/ruby
# Status to View (String with attributes)
class View < Hash
  def initialize(stat={})
    if stat.key?('list')
      update(stat)
    else
      ary=self['list']=[]
      stat.each{|k,v|
        case k
        when 'id','frame','class'
          self[k]=v
        end
        ary << {'id'=>k, 'val'=>v}
      }
    end
  end

  def add_label(odb)
    if odb
      require "liblabel"
      Label.new(odb).convert(self)
    end
    self
  end

  def add_group(odb)
    if odb
      require "libgroup"
      Group.new(odb).convert(self)
    end
    self
  end

  def init_sym(odb)
    if odb
      require "libsymdb"
      require "libsym"
      sym=SymDb.new
      sym.update(odb.symtbl)
      @sdb=Sym.new(sym,odb)
    end
    self
  end

  def conv_sym
    if @sdb
      @sdb.convert(self)
    end
    self
  end

  def prt
    pr=Print.new
    pr.print(self)
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
    (header+list).join("\n")
  end
end
