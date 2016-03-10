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
        html = enclose('html')
        _mk_head(html.enclose('head'))
        @div = html.enclose('body').enclose('div', class: 'outline')
        @div.element('div', @dbi[:label], class: 'title')
      end

      private

      def _mk_head(parent)
        parent.element('title', 'CIAX-XML')
        atrb = { rel: 'stylesheet', type: 'text/css', href: 'ciax-xml.css' }
        parent.element('link', nil, atrb)
        fmt = 'var Type="status",Site="%s",Host="%s",Port="%s";'
        script = format(fmt, @dbi[:id], @dbi[:host], @dbi[:port])
        _mk_script(parent, '', JQUERY)
        _mk_script(parent, script)
        _mk_script(parent, '', 'ciax-xml.js')
        self
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
        tr = _mk_line(_mk_tbody, %i(time elapsed))
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
          td.element('span', '*******', id: id, class: 'normal')
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

    # Html Control
    class Control < Status
      def initialize(dbi, grpary = [])
        super(dbi)
        _mk_ctl_grp(grpary)
      end

      private

      def _mk_ctl_grp(grpary)
        return if !@gdb || grpary.empty?
        tbody = _mk_tbody('Controls')
        grpary.each do |gid|
          id_err(@gdb.keys.inspect) unless @gdb.key?(gid)
          _mk_ctl_line(gid, tbody)
        end
        self
      end

      def _mk_ctl_line(gid, tbody)
        return unless @udb
        uary = @gdb[gid][:units] || return
        td = tbody.enclose('tr').enclose('td', class: 'item')
        uary.each do|uid|
          next if _mk_ctl_unit(td, uid)
          errary = @udb.map { |k, v| itemize(k, v[:label]) }
          errary.unshift('Wrong CTL Unit')
          give_up(errary.join("\n"))
        end
        self
      end

      def _mk_ctl_unit(parent, uid)
        return unless @udb.key?(uid)
        uat = @udb[uid]
        _mk_label(parent, uat)
        umem = uat[:members]
        if umem.size > 2
          _mk_select(parent, umem, uid)
        else
          _mk_button(parent, umem)
        end
      end

      def _mk_label(parent, atrb)
        return unless atrb[:label]
        label = atrb[:label].gsub(/\[.*\]/, '')
        parent.element('span', label, class: 'ctllabel')
      end

      def _mk_select(parent, umem, uid)
        span = parent.enclose('span', class: 'center')
        sel = span.enclose('select', name: uid, onchange: 'seldv(this)')
        (['--select--'] + umem).each do|id|
          sel.element('option', id)
        end
        self
      end

      def _mk_button(parent, umem)
        span = parent.enclose('span', class: 'center')
        umem.each do|id|
          label = @idx[id][:label]
          _elem_button(span, id, label)
        end
        self
      end
    end

    if __FILE__ == $PROGRAM_NAME
      begin
        dbi = Ins::Db.new.get(ARGV.shift)
      rescue InvalidARGS
        Msg.usage '[id] (ctl)'
      end
      begin
        tbl = Control.new(dbi, ARGV)
        puts tbl
      rescue InvalidARGS
        Msg.usage '[id] (ctl)'
      end
    end
  end
end
