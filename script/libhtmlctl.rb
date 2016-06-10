#!/usr/bin/ruby
require 'libhtmltbl'
# CIAX-XML
module CIAX
  # HTML Table generation
  module HtmlTbl
    # Html Control
    class Control < Status
      def initialize(dbi, grpary = [])
        super(dbi)
        _mk_ctl_grp(grpary)
        return unless @dbi[:watch] && !grpary.include?('-')
        _elem_button(@ctltd, 'stop')
      end

      private

      def _mk_ctl_grp(grpary)
        _check_group if grpary.empty?
        grpary.each do |gid|
          next if gid == '-'
          _check_group(gid)
          tbody = _mk_tbody('Control ' + @gdb[gid][:caption])
          _mk_ctl_column(gid, tbody)
        end
        self
      end

      def _mk_ctl_column(gid, tbody)
        return unless @udb
        member = @gdb[gid][:units] || return
        member.sort.each_slice(3) do |uary|
          td = tbody.enclose('tr').enclose('td', class: 'item')
          _mk_ctl_line(td, uary)
        end
      end

      def _mk_ctl_line(td, uary)
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
        _mk_select(parent, umem, uid)
      end

      def _mk_label(parent, atrb)
        return unless atrb[:label]
        label = atrb[:label].gsub(/\[.*\]/, '')
        parent.element('span', label, class: 'control-label')
      end

      def _mk_select(parent, umem, uid)
        span = parent.enclose('span', class: 'center')
        sel = span.enclose('select', name: uid, onchange: 'seldv(this)')
        sel.element('option', '--select--')
        umem.each do|id|
          label = @idx[id][:label] || id
          sel.element('option', label, value: id)
        end
        self
      end

      def _check_group(gid = nil)
        return if @gdb.key?(gid)
        msg = @gdb.map { |k, v| Msg.itemize(k, v[:caption]) }.join("\n")
        fail InvalidCMD, msg
      end
    end

    if __FILE__ == $PROGRAM_NAME
      begin
        dbi = Ins::Db.new.get(ARGV.shift)
      rescue InvalidARGS
        Msg.usage '[id] [grp]'
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
