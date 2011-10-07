#!/usr/bin/ruby
require 'libmsg'
class HtmlTbl < Array
  def initialize(adb)
    Msg.type?(adb,AppDb)
    @label = adb[:status][:label]
    push "<div class=\"outline\">"
    push "<div class=\"title\">#{adb['label']}</div>"
    group = adb[:status][:group] || adb[:status][:select].keys
    get_group(group)
    push "</div>"
  end

  private
  def get_group(group)
    group.each{|g|
      arys,ids=g.partition{|e| Array === e}
      unless ids.empty?
        cap=@label[ids.first] || next
      end
      push "<table><tbody>"
      push  "<tr><th colspan=\"6\">#{cap}</th></tr>" if cap
      arys.each{|a|
        get_element(a)
      }
      push "</tbody></table>"
    }
    self
  end

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
    adb=InsDb.new(id).cover_app
  rescue SelectID
    warn "Usage: #{$0} [id]"
    Msg.exit
  end
  puts HtmlTbl.new(adb)
end
