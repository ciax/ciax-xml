#!/usr/bin/ruby
require 'libmsg'

module CIAX
  class HtmlTbl < Array
    include Msg
    def initialize(adb)
      adbs=type?(adb,Dbi)[:status]
      @index=adbs[:index]
      push "<div class=\"outline\">"
      push "<div class=\"title\">#{adb['label']}</div>"
      get_element(['time','elapse'],'',2)
      adbs[:group].each{|k,g|
        cap=g["caption"] || next
        get_element(g[:members],cap,g["column"].to_i)
      }
      push "</div>"
    end

    private
    def get_element(members,cap='',col=6)
      push "<table><tbody>"
      push  "<tr><th colspan=\"6\">#{cap}</th></tr>" unless cap.empty?
      members.each_slice(col){|da|
        push "<tr>"
        da.each{|id|
          label=(@index[id]||{})['label']||id.upcase
          push "<td class=\"item\">"
          push "<span class=\"label\">#{label}</span>"
          push "<span id=\"#{id}\" class=\"normal\">*******</span>"
          push "</td>"
        }
        push "</tr>"
      }
      push "</tbody></table>"
      self
    end
  end

  if __FILE__ == $0
    require "libinsdb"
    id=ARGV.shift
    begin
      adb=Ins::Db.new.get(id)
    rescue InvalidID
      Msg.usage "[id]"
    end
    puts HtmlTbl.new(adb)
  end
end
