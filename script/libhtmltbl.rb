#!/usr/bin/env ruby
require 'libxmlfmt'
require 'libinsdb'
# CIAX-XML
module CIAX
  # HTML Table generation
  module HtmlTbl
    # Page Header
    class Header < Xml::Format
      def initialize(dbi)
        super()
        @dbi = type?(dbi, Dbx::Item)
        dbc = @dbi[:command]
        @idx = dbc[:index]
        @gdb = dbc[:group]
        @udb = dbc[:unit]
        ___mk_top
      end

      private

      def ___mk_top
        push('<!DOCTYPE html>')
        html = enclose('html', lang: 'en-US')
        ___mk_head(html.enclose('head'))
        @div = html.enclose('body').enclose('div', class: 'outline')
        @div.element('div', @dbi[:label], class: 'title')
      end

      def ___mk_head(parent)
        parent.element('meta', '', charset: 'utf-8')
        parent.element('title', "CIAX-XML(#{@dbi[:id]})")
        atrb = { rel: 'stylesheet', type: 'text/css', href: 'ciax-xml.css' }
        parent.element('link', nil, atrb)
        ___mk_script_tags(parent)
      end

      def ___mk_script_tags(parent)
        fmt = 'var type="status",site="%s",Host="%s",port="%s";'
        script = format(fmt, @dbi[:id], @dbi[:host], @dbi[:port])
        __mk_script(parent, '', 'jquery-3.0.0.min.js')
        __mk_script(parent, script)
        __mk_script(parent, '', 'ciax-xml.js')
        __mk_script(parent, '', 'status.js')
        __mk_script(parent, '$(document).ready(init);')
      end

      def __mk_script(parent, text, src = nil)
        atrb = { type: 'text/javascript' }
        atrb[:src] = src + '?t=' + now_msec.to_s if src
        parent.element('script', text, atrb)
        self
      end
    end

    # Html Status
    class Status < Header
      def initialize(dbi)
        super
        @adbs = @dbi[:status]
        ___mk_thead
        ___mk_stat
      end

      private

      def ___mk_thead
        @dbs = @adbs[:index]
        tr = __mk_line(_mk_tbody, %i(time elapsed msg))
        @ctltd = tr.enclose('td', class: 'center')
        # add buttons here
        _elem_button(@ctltd, 'upd')
        self
      end

      def ___mk_stat
        @adbs[:group].values.each do |g|
          cap = g[:caption] || next
          ___mk_column(g[:members], cap, g[:column])
        end
        self
      end

      def ___mk_column(members, cap = '', col = nil)
        col = col.to_i > 0 ? col.to_i : 6
        tbody = _mk_tbody(cap)
        members.each_slice(col) do |da|
          __mk_line(tbody, da, true)
        end
        tbody
      end

      def __mk_line(parent, member, add_graph = nil)
        tr = parent.enclose('tr')
        member.each do |id|
          label = (@dbs[id] || {})[:label] || id.upcase
          td = tr.enclose('td', class: 'item')
          td.element('span', label, class: 'label', title: id)
          atrb = { id: id, class: 'normal' }
          ___add_graph(id, atrb) if add_graph
          td.element('strong', '*****', atrb)
        end
        tr
      end

      def _mk_tbody(cap = nil)
        tbody = @div.enclose('table').enclose('tbody')
        tbody.enclose('tr').element('th', cap, colspan: 6) if cap
        tbody
      end

      def _elem_button(parent, id)
        atrb = { class: id, onclick: "#{id}();" }
        parent.element('button', id.upcase, atrb)
      end

      def ___add_graph(id, atrb)
        atrb[:onclick] = format("open_graph('%s','%s');", @dbi[:id], id)
        atrb
      end
    end

    if __FILE__ == $PROGRAM_NAME
      Opt::Get.new('[id] (ctl)') do |_opt, args|
        puts Status.new(Ins::Db.new.get(args.shift))
      end
    end
  end
end
