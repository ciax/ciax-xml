#!/usr/bin/ruby
require 'libmsg'
class HtmlTbl < Array
  def initialize(adb)
    sdb=Msg.type?(adb,App::Db)[:status]
    @label = sdb[:label]
    push "<div class=\"outline\">"
    push "<div class=\"title\">#{adb['label']}</div>"
    sdb[:group].each{|k,g|
      cap=sdb[:caption][k] || next
      push "<table><tbody>"
      push  "<tr><th colspan=\"6\">#{cap}</th></tr>" unless cap.empty?
      get_element(g,sdb[:column][k].to_i)
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
  app=ARGV.shift
  begin
    adb=Ins::Db.new(id).cover_app
  rescue InvalidDEV
    Msg.usage "[id]"
  end
  puts HtmlTbl.new(adb)
end
