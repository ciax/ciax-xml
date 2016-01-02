#!/usr/bin/ruby
require 'libxmlfmt'
require 'libinsdb'
# CIAX-XML
module CIAX
  # HTML Table generation
  class HtmlTbl < Xml::Format
    JQUERY = 'http://ajax.googleapis.com/ajax/libs/jquery/1.11.0/jquery.min.js'
    def initialize(dbi)
      super()
      @dbi = type?(dbi, Dbi)
      html = enclose('html')
      mk_head(html.enclose('head'))
      @div = html.enclose('body').enclose('div', class: 'outline')
      @div.element('div', @dbi[:label], class: 'title')
    end

    def mk_head(head)
      head.element('title', 'CIAX-XML')
      head.element('link', nil, rel: 'stylesheet', type: 'text/css', href: 'ciax-xml.css')
      script = format('var Type="status",Site="%s",Port="%s";', @dbi[:id], @dbi[:port])
      mk_script(head, '', JQUERY)
      mk_script(head, script)
      mk_script(head, '', 'ciax-xml.js')
      self
    end

    def mk_stat
      adbs = @dbi[:status]
      @index = adbs[:index]
      get_element(%i(time elapsed), '', 2)
      adbs[:group].values.each do|g|
        cap = g[:caption] || next
        get_element(g[:members], cap, g['column'])
      end
      self
    end

    def get_ctl_grp(grpary)
      return if grpary.empty?
      gidx = @dbi[:command][:group] || return
      tr = mk_tbody('Controls').enclose('tr')
      grpary.each{ |gid|
        id_err(gidx.keys.inspect) unless gidx.key?(gid)
        get_ctl_unit(gidx[gid][:units] || [], tr)
      }
      self
    end

    def get_ctl_unit(unitary, tr = nil)
      return if unitary.empty?
      tr ||= mk_tbody('Controls').enclose('tr')
      uidx = @dbi[:command][:unit] || return
      unitary.each do|uid|
        udb = uidx[uid]
        if udb
          td = tr.enclose('td', class: 'item')
          if udb[:label]
            label = udb[:label].gsub(/\[.*\]/, '')
            td.element('span', label, class: 'ctllabel')
          end
          umem = udb[:members]
          if umem.size > 2
            get_select(td, umem, uid)
          else
            get_button(td, umem)
          end
        else
          give_up("Wrong CTL Unit\n" + uidx.map { |k, v| itemize(k, v[:label]) }.join("\n"))
        end
      end
      self
    end

    private

    def mk_script(head, text, src = nil)
      atrb = { type: 'text/javascript' }
      atrb[:src] = src if src
      head.element('script', text, atrb)
      self
    end

    def mk_tbody(cap = nil)
      tbody = @div.enclose('table').enclose('tbody')
      tbody.enclose('tr').element('th', cap, colspan: 6) if cap
      tbody
    end

    def get_element(members, cap = '', col = nil)
      col = col.to_i > 0 ? col.to_i : 6
      tbody = mk_tbody(cap)
      members.each_slice(col) do|da|
        tr = tbody.enclose('tr')
        da.each do|id|
          label = (@index[id] || {})[:label] || id.upcase
          td = tr.enclose('td', class: 'item')
          td.element('span', label, class: 'label')
          td.element('span', '*******', id: id, class: 'normal')
        end
      end
      self
    end

    def get_select(td, umem, uid)
      span = td.enclose('span', class: 'center')
      sel = span.enclose('select', id: uid, onchange: 'seldv(this)')
      umem.each do|id|
        sel.element('option', id)
      end
      self
    end

    def get_button(td, umem)
      umem.each do|id|
        span = td.enclose('span', class: 'center')
        label = @dbi[:command][:index][id][:label].upcase
        span.element('input', nil,  class: 'button', type: 'button', value: label,
                                    onclick: "dvctl('#{id}')")
      end
      self
    end
  end

  if __FILE__ == $PROGRAM_NAME
    id = ARGV.shift
    begin
      dbi = Ins::Db.new.get(id)
    rescue InvalidID
      Msg.usage '[id] (ctl)'
    end
    tbl = HtmlTbl.new(dbi)
    tbl.mk_stat
    begin
      tbl.get_ctl_grp(ARGV)
      puts tbl
    rescue InvalidID
      Msg.usage '[id] (ctl)'
    end
  end
end
