#!/usr/bin/ruby
require 'libmsg'

module CIAX
  class HtmlTbl < Array
    include Msg
    def initialize(dbi)
      adbs=type?(dbi,Dbi)[:status]
      @index=adbs[:index]
      push "<div class=\"outline\">"
      push "<div class=\"title\">#{dbi['label']}</div>"
      get_element(['time','elapsed'],'',2)
      adbs[:group].each{|k,g|
        cap=g["caption"] || next
        get_element(g[:members],cap,g["column"])
      }
      push "</div>"
    end

    private
    def get_element(members,cap='',col=nil)
      col= col.to_i > 0 ? col.to_i : 6
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
      dbi=Ins::Db.new.get(id)
    rescue InvalidID
      Msg.usage "[id]"
    end
    puts HtmlTbl.new(dbi)
  end
end
