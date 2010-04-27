#!/usr/bin/ruby
require "libxmldb"
require "libmodstat"
class ObjStat < XmlDb
  include ModStat

  public
  def objstat(cstat)
    @cstat=cstat
    get_stat
    return @stat
  end

  protected
  def get_stat
    each_node do |c| # var
      a=c.add_attr
      ref=a.delete('ref') || raise(IndexError,"No refernce")
      set=@cstat[ref] || raise(IndexError,"No reference for #{a['ref']}") 
      id=a.delete('id') || ref
      a['label']=set['label'].sub(/\[.*\]/,a['label']) if a['label']
      val=a['val']
      set.update(a)
      c.symbol(val,set)
      @stat["#{@type}:#{id}"]=set
    end
  end

end




