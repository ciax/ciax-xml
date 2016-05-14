#!/usr/bin/ruby
require 'libxmlfmt'
require 'libinsdb'
# CIAX-XML
module CIAX
  # HTML Table generation
  module HtmlTbl
    JQUERY = 'http://ajax.googleapis.com/ajax/libs/jquery/1.11.0/jquery.min.js'
    # Page Header
    class Header < Xml::Format
      def initialize(dbi)
        super()
        @dbi = type?(dbi, Dbi)
        cdb = @dbi[:command]
        @idx = cdb[:index]
        @gdb = cdb[:group]
        @udb = cdb[:unit]
        push('<!DOCTYPE html>')
        html = enclose('html', lang: 'en-US')
        _mk_head(html.enclose('head'))
        @div = html.enclose('body').enclose('div', class: 'outline')
        @div.element('div', @dbi[:label], class: 'title')
      end

      private

      def _mk_head(parent)
        parent.element('meta','', charset: 'utf-8')
        parent.element('title', 'CIAX-XML')
        atrb = { rel: 'stylesheet', type: 'text/css', href: 'ciax-xml.css' }
        parent.element('link', nil, atrb)
        fmt = 'var type="status",site="%s",Host="%s",port="%s";'
        script = format(fmt, @dbi[:id], @dbi[:host], @dbi[:port])
        _mk_script(parent, '', JQUERY)
        _mk_script(parent, script)
        _mk_script(parent, '', 'ciax-xml.js')
        _mk_script(parent, '', 'status.js')
        _mk_script(parent,'$(document).ready(init);')
      end

      def _mk_script(parent, text, src = nil)
        atrb = { type: 'text/javascript' }
        atrb[:src] = src if src
        parent.element('script', text, atrb)
        self
      end
    end

    # Html Status
    class Status < Header
      def initialize(dbi)
        super
        @adbs = @dbi[:status]
        _mk_thead
        _mk_stat
      end

      private

      def _mk_thead
        @sdb = @adbs[:index]
        tr = _mk_line(_mk_tbody, %i(time elapsed msg))
        td = tr.enclose('td', class: 'center')
        _elem_button(td, 'upd')
        self
      end

      def _mk_stat
        @adbs[:group].values.each do|g|
          cap = g[:caption] || next
          _mk_column(g[:members], cap, g[:column])
        end
        self
      end

      def _mk_column(members, cap = '', col = nil)
        col = col.to_i > 0 ? col.to_i : 6
        tbody = _mk_tbody(cap)
        members.each_slice(col) do|da|
          _mk_line(tbody, da)
        end
        tbody
      end

      def _mk_line(parent, member)
        tr = parent.enclose('tr')
        member.each do|id|
          label = (@sdb[id] || {})[:label] || id.upcase
          td = tr.enclose('td', class: 'item')

          td.element('span', label, class: 'label')
          td.element('span', '*******', id: id, class: 'val')
        end
        tr
      end

      def _mk_tbody(cap = nil)
        tbody = @div.enclose('table').enclose('tbody')
        tbody.enclose('tr').element('th', cap, colspan: 6) if cap
        tbody
      end

      def _elem_button(parent, id, label = nil)
        atrb = { class: 'button', type: 'button' }
        atrb[:value] = (label || id).upcase
        atrb[:onclick] = "dvctl('#{id}')"
        parent.element('input', nil, atrb)
      end
    end

    if __FILE__ == $PROGRAM_NAME
      begin
        dbi = Ins::Db.new.get(ARGV.shift)
      rescue InvalidARGS
        Msg.usage '[id] (ctl)'
      end
      begin
        tbl = Status.new(dbi)
        puts tbl
      rescue InvalidARGS
        Msg.usage '[id] (ctl)'
      end
    end
  end
end
