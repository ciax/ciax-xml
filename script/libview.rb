#!/usr/bin/ruby
require "libsymtbl"
require "libcircular"
class View
  attr_reader :tbl

  def initialize(key)
    @key=key
    @c=Circular.new(4)
    @sdb=SymTbl.new
    @tbl={}
    @plabel=[]
  end

  def get_view(stat)
    st={ }
    @tbl.each{|k,v|
      sym=@sdb.get_symbol(v[:symbol],stat[k])
      sym['label']=v[:label]
      sym['group']=v[:group]
      st[k]=sym
    }
    st
  end

  def set_tbl(e)
    e[@key] || return
    label=yield(e['label'])||"Noname"
    clabel=label.split(' ')
    if clabel.first == @plabel.first || clabel.last == @plabel.last
      @c.next
    else
      @c.reset
    end
    @plabel=clabel
    id=yield(e[@key])
    @tbl[id]={:label=>label,:symbol=>e['symbol'],:group=>@c.times }
  end
end
