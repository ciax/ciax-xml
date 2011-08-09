#!/usr/bin/ruby
require "json"
require "libviewopt"

class HtmlTbl < Array
  def initialize(odb)
    @odb=odb
    stat={'time' => ''}.update(odb.status[:select])
    @view=ViewOpt.new(odb,stat).opt('al')
    push "<div class=\"outline\">"
    push "<div class=\"title\">#{@odb['id']}</div>"
    group = @view['group'] || @view['list'].keys
    get_group(group)
    push "</div>"
  end

  private
  def get_group(group)
    group.each{|g|
      push "<table><tbody>"
      unless Array === g[0]
        cap,*g=g
        push "<tr><th colspan=\"6\">#{cap}</th></tr>"
      end
      g.each{|a|
        get_element(a)
      }
      push "</tbody></table>"
    }
    self
  end

  def get_element(ary,col=6)
    da=ary.dup
    while da.size > 0
      push "<tr>"
      da.shift(col).each{|id|
        next unless @view['list'].key?(id)
        item=@view['list'][id]
        label=@view['label'][id]||id.upcase
        push "<td class=\"item\">"
        push "<span class=\"label\">#{label}</span>"
        push "<span id=\"#{id}\" class=\"normal\">*******</span>"
        push "</td>"
      }
      push "</tr>"
    end
    self
  end
end
