#!/usr/bin/ruby
# Status to View (String with attributes)
require "json"
require "libviewopt"
require "libprint"

class HtmlTbl
  def initialize(odb)
    @odb=odb
    @view=ViewOpt.new(odb).opt('al')
  end

  def to_s
    group = @view['group'] || @view['list'].keys
    list=[]
    list << "<div class=\"outline\">"
    list << "<div class=\"title\">#{@odb['id']}</div>"
    list << arc_print(group)
    list << "</div>"
    list.join("\n")
  end

  private
  def arc_print(ary)
    ids=[]
    group=[]
    list=[]
    ary.each{|i|
      case i
      when Array
        group << i
      else
        ids << i
      end
    }
    if group.empty?
      list+=fold(ids.map{|i|
        get_element(i)
      })
    else
      list << "<table><tbody>"
      list << get_title(ids[0]) unless ids.empty?
      group.each{|a|
        list+=arc_print(a)
      }
      list << "</tbody></table>"
    end
  end

  def get_title(title)
    "<tr><th class=\"caption\" colspan=\"10\">#{title}</th></tr>"
  end

  def get_element(id)
    return '' unless @view['list'].key?(id)
    item=@view['list'][id]
    label=item['label']||id.upcase
    list=["<td class=\"label\">#{label}</td>"]
    list << "<td class=\"value\">"
    list << "<div id=\"#{id}\" class=\"normal\">*******</div>"
    list << "</td>"
  end

  def fold(ary,col=3)
    da=ary.dup
    row=[]
    while da.size > 0
      row << "<tr>"
      row+=da.shift(col)
      row << "</tr>"
    end
    row
  end
end
