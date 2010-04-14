#!/usr/bin/ruby
require "libobj"
require "libstat"
TopNode='//status'
class ObjStat < Obj
  include Stat
  public
  def objstat(cstat)
    @cstat=cstat
    @ostat=Hash.new
    get_stat
    return @ostat
  end

  protected
  def get_stat
    each_node do |c| # var
      a=c.attr_to_hash
      ref=a['ref']
      a.delete('ref')
      set=@cstat[ref] || raise(IndexError,"No reference for #{a['ref']}") 
      id=a['id'] ? a.delete('id') : ref
      val=a['val']
      set.update(a)
      c.symbol(val,set)
      @ostat[id]=set
    end
  end

end

