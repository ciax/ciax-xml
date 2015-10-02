#!/usr/bin/ruby
require 'libmsg'

module CIAX
  class HtmlTbl < Array
    include Msg
    def initialize(dbi)
      @dbi = type?(dbi, Dbi)
      push '<html>'
      push '<head>'
      push '<title>CIAX-XML</title>'
      push '<link rel="stylesheet" type="text/css" href="ciax-xml.css" />'
      push '<script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.10.1/jquery.min.js"></script>'
      push '<script type="text/javascript">var Type="status",Site="' + @dbi['id'] + '",Port="' + @dbi['port'] + '";</script>'
      push '<script type="text/javascript" src="ciax-xml.js"></script>'
      push '</head>'
      push '<body>'
      push '<div class="outline">'
      push '<div class="title">' + @dbi['label'] + '</div>'
    end

    def fin
      push '</div>'
      push '</body>'
      push '</html>'
      self
    end

    def get_stat
      adbs = @dbi[:status]
      @index = adbs[:index]
      get_element(['time', 'elapsed'], '', 2)
      adbs[:group].values.each{|g|
        cap = g['caption'] || next
        get_element(g[:members], cap, g['column'])
      }
      self
    end

    def get_ctl(unitary)
      uidx = @dbi[:command][:unit] || return
      push '<table><tbody>'
      push '<tr>'
      push '<th colspan="6">Controls</th></tr>'
      push '<tr>'
      unitary.each{|unit|
        udb = uidx[unit]
        if udb
          push '<td class="item">'
          push '<span class="ctllabel">' + udb['label'] + '</span>'
          udb[:members].each{|id|
            push '<span class="center">'
            label = @dbi[:command][:index][id]['label'].upcase
            push '<input class="button" type="button" value="' + label + '" onclick="dvctl(' + "'#{id}'" + ')"/>'
            push '</span>'
          }
          push '</td>'
        else
          abort("Wrong CTL Unit\n" + uidx.map { |k, v| item(k, v['label']) }.join("\n"))
        end
      }
      push '</tr>'
      push '</tbody></table>'
      self
    end

    private
    def get_element(members, cap = '', col = nil)
      col = col.to_i > 0 ? col.to_i : 6
      push '<table><tbody>'
      push  "<tr><th colspan=\"6\">#{cap}</th></tr>" unless cap.empty?
      members.each_slice(col){|da|
        push '<tr>'
        da.each{|id|
          label = (@index[id] || {})['label'] || id.upcase
          push "<td class=\"item\">"
          push "<span class=\"label\">#{label}</span>"
          push "<span id=\"#{id}\" class=\"normal\">*******</span>"
          push '</td>'
        }
        push '</tr>'
      }
      push '</tbody></table>'
      self
    end
  end

  if __FILE__ == $0
    require 'libinsdb'
    id = ARGV.shift
    begin
      dbi = Ins::Db.new.get(id)
    rescue InvalidID
      Msg.usage '[id] (ctl)'
    end
    tbl = HtmlTbl.new(dbi)
    tbl.get_stat
    tbl.get_ctl(ARGV)
    puts tbl.fin
  end
end
