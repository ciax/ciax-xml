#!/usr/bin/ruby
require 'libmsg'

module CIAX
  class HtmlTbl < Array
    include Msg
    def initialize(adb)
      @label = type?(adb,App::Db)[:status][:label]
      push "<div class=\"outline\">"
      push "<div class=\"title\">#{adb['label']}</div>"
      adb[:statgrp].each{|k,g|
        cap=g["caption"] || next
        push "<table><tbody>"
        push  "<tr><th colspan=\"6\">#{cap}</th></tr>" unless cap.empty?
        get_element(g[:members],g["column"].to_i)
        push "</tbody></table>"
      }
      push "</div>"
    end

    private
    def get_element(hash,col=6)
      hash.keys.each_slice(col){|da|
        push "<tr>"
        da.each{|id|
          next unless hash.key?(id)
          label=hash[id]||id.upcase
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
      adb=Ins::Db.new.set(id).cover_app
    rescue InvalidID
      Msg.usage "[id]"
    end
    puts HtmlTbl.new(adb)
  end
end
