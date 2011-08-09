#!/usr/bin/ruby
# Status to View (String with attributes)
require "json"
require "libviewopt"
require "libprint"

class HtmlTbl < Array
  def initialize(odb)
    @odb=odb
    @view=ViewOpt.new(odb,odb.status[:select]).opt('al')
    push "<div class=\"outline\">"
    push "<div class=\"title\">#{@odb['id']}</div>"
    group = @view['group'] || @view['list'].keys
    group.each{|g|
      arc_group(g)
    }
    push "</div>"
  end

  private
  def arc_group(ary)
    ids=[]
    group=[]
    ary.each{|i|
      case i
      when Array
        group << i
      else
        ids << i
      end
    }
    if group.empty?
      fold(ids){|i| get_element(i)}
    else
      open_group(ids[0])
      group.each{|a|
        arc_group(a)
      }
      close_group
    end
  end

  def open_group(cap=nil)
    push "<table><tbody>"
    if cap
      push "<tr>"
      push "<th class=\"caption\" colspan=\"6\">#{cap}</th>"
      push "</tr>"
    end
    self
  end

  def close_group
    push "</tbody></table>"
    self
  end

  def get_element(id)
    return self unless @view['list'].key?(id)
    item=@view['list'][id]
    label=item['label']||id.upcase
    push "<td class=\"item\">"
    push "<span class=\"label\">#{label}</span>"
    push "<span id=\"#{id}\" class=\"normal\">*******</span>"
    push "</td>"
    self
  end

  def fold(ary,col=6)
    da=ary.dup
    while da.size > 0
      push "<tr>"
      da.shift(col).each{|e|
        yield e
      }
      push "</tr>"
    end
    self
  end
end
