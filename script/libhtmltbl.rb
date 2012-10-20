#!/usr/bin/ruby
require 'libmsg'
class HtmlTbl < Array
  def initialize(idb)
    sdb=Msg.type?(idb[:app],App::Db)[:status]
    @label = sdb[:label]
    push "<div class=\"outline\">"
    push "<div class=\"title\">#{idb['label']}</div>"
    gdb=sdb[:group]
    gdb[:items].each{|k,g|
      cap=gdb[:caption][k] || next
      push "<table><tbody>"
      push  "<tr><th colspan=\"6\">#{cap}</th></tr>" unless cap.empty?
      get_element(g,gdb[:column][k].to_i)
      push "</tbody></table>"
    }
    push "</div>"
  end

  private
  def get_element(ary,col=6)
    ary.each_slice(col){|da|
      push "<tr>"
      da.each{|id|
        next unless @label.key?(id)
        label=@label[id]||id.upcase
        push "<td class=\"item\">"
        push "<span class=\"label\">#{label}</span>"
        push "<span id=\"#{id}\" class=\"normal\">*******</span>"
        push "</td>"
      }
      push "</tr>"
    }
    self
  end
end

if __FILE__ == $0
  require "libinsdb"
  id=ARGV.shift
  begin
    idb=Ins::Db.new(id).cover_loc
  rescue InvalidID
    Msg.usage "[id]"
  end
  puts HtmlTbl.new(idb)
end
