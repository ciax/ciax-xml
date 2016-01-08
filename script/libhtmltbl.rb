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
      @gdb = @dbi[:command][:group]
      @udb = @dbi[:command][:unit]
      html = enclose('html')
      mk_head(html.enclose('head'))
      @div = html.enclose('body').enclose('div', class: 'outline')
      @div.element('div', @dbi[:label], class: 'title')
    end

    def mk_head(head)
      head.element('title', 'CIAX-XML')
      head.element('link', nil,
                   rel: 'stylesheet', type: 'text/css', href: 'ciax-xml.css')
      script = format('var Type="status",Site="%s",Port="%s";',
                      @dbi[:id], @dbi[:port])
      _mk_script(head, '', JQUERY)
      _mk_script(head, script)
      _mk_script(head, '', 'ciax-xml.js')
      self
    end

    def mk_stat
      adbs = @dbi[:status]
      @index = adbs[:index]
      _mk_line(_mk_tbody,%i(time elapsed))
      adbs[:group].values.each do|g|
        cap = g[:caption] || next
        _mk_column(g[:members], cap, g['column'])
      end
      self
    end

    def mk_ctl_grp(grpary)
      return if !@gdb || grpary.empty?
      tr = _mk_tbody('Controls').enclose('tr')
      grpary.each do |gid|
        id_err(@gdb.keys.inspect) unless @gdb.key?(gid)
        mk_ctl_form(gid, tr)
      end
      self
    end

    def mk_ctl_form(gid, tr = nil)
      return unless @udb
      uary = @gdb[gid][:units] || return
      tr ||= _mk_tbody('Controls').enclose('tr')
      form = tr.enclose('form', name: gid, action: '')
      uary.sort.each do|uid|
        next if mk_ctl_unit(form, uid)
        errary = @udb.map { |k, v| itemize(k, v[:label]) }
        errary.unshift('Wrong CTL Unit')
        give_up(errary.join("\n"))
      end
      self
    end

    def mk_ctl_unit(form, uid)
      return unless @udb.key?(uid)
      td = form.enclose('td', class: 'item')
      uat = @udb[uid]
      mk_ctl_label(td, uat)
      umem = uat[:members]
      if umem.size > 2
        _mk_select(td, umem, uid)
      else
        _mk_button(td, umem)
      end
    end

    def mk_ctl_label(td, udb)
      return unless udb[:label]
      label = udb[:label].gsub(/\[.*\]/, '')
      td.element('span', label, class: 'ctllabel')
    end

    private

    def _mk_script(head, text, src = nil)
      atrb = { type: 'text/javascript' }
      atrb[:src] = src if src
      head.element('script', text, atrb)
      self
    end

    def _mk_tbody(cap = nil)
      tbody = @div.enclose('table').enclose('tbody')
      tbody.enclose('tr').element('th', cap, colspan: 6) if cap
      tbody
    end

    def _mk_column(members, cap = '', col = nil)
      col = col.to_i > 0 ? col.to_i : 6
      tbody = _mk_tbody(cap)
      members.each_slice(col) do|da|
        _mk_line(tbody, da)
      end
      tbody
    end

    def _mk_line(tbody, member)
      tr = tbody.enclose('tr')
      member.each do|id|
        label = (@index[id] || {})[:label] || id.upcase
        td = tr.enclose('td', class: 'item')
        td.element('span', label, class: 'label')
        td.element('span', '*******', id: id, class: 'normal')
      end
      tr
    end

    def _mk_select(td, umem, uid)
      span = td.enclose('span', class: 'center')
      sel = span.enclose('select', name: uid, onchange: 'seldv(this)')
      umem.each do|id|
        sel.element('option', id)
      end
      self
    end

    def _mk_button(td, umem)
      umem.each do|id|
        span = td.enclose('span', class: 'center')
        label = @dbi[:command][:index][id][:label].upcase
        atrb = {class: 'button', type: 'button', value: label, onclick: "dvctl('#{id}')"}
        span.element('input', nil, atrb)
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
      tbl.mk_ctl_grp(ARGV)
      puts tbl
    rescue InvalidID
      Msg.usage '[id] (ctl)'
    end
  end
end
