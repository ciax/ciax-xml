#!/usr/bin/ruby
require "libobj"
TopNode='//status'
class ObjStat < Obj
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
      set=@cstat[a['ref']] || raise(IndexError,"No reference for #{a['ref']}") 
      a.delete('ref')
      id=a['id']
      a.delete('id')
      val=a['val']
      set.update(a)
      c.node_with_name('symbol') do |d|
        case d['type']
        when 'range'
          d.each_node do |e|
            min,max=e.text.split(':')
            next if max.to_f < val.to_f
            next if min.to_f > val.to_f
            set.update(e.attr_to_hash)
            break
          end
        else
          d.node_with_text(val) do |e|
            set.update(e.attr_to_hash)
          end
        end
      end
      @ostat[id]=set
    end
  end

end

