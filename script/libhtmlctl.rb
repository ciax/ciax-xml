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
        _mk_ctl_grp_(grpary)
        return unless @dbi[:watch] && !grpary.include?('-')
        _elem_button(@ctltd, 'stop')
      end

      private

      def _mk_ctl_grp_(grpary)
        _check_group if grpary.empty?
        grpary.each do |gid|
          next if gid == '-'
          _check_group(gid)
          tbody = _mk_tbody('Control ' + @gdb[gid][:caption])
          _mk_ctl_column_(gid, tbody)
        end
        self
      end

      def _mk_ctl_column_(gid, tbody)
        return unless @udb
        member = @gdb[gid][:units] || return
        member.sort.each_slice(3) do |uary|
          td = tbody.enclose('tr').enclose('td', class: 'item')
          _mk_ctl_line_(td, uary)
        end
      end

      def _mk_ctl_line_(td, uary)
        uary.each do |uid|
          next if _mk_ctl_unit_(td, uid)
          errary = @udb.map { |k, v| itemize(k, v[:label]) }
          errary.unshift('Wrong CTL Unit')
          give_up(errary.join("\n"))
        end
        self
      end

      def _mk_ctl_unit_(parent, uid)
        return unless @udb.key?(uid)
        uat = @udb[uid]
        _mk_label_(parent, uat)
        umem = uat[:members]
        _mk_select_(parent, umem, uid)
      end

      def _mk_label_(parent, atrb)
        return unless atrb[:label]
        label = atrb[:label].gsub(/\[.*\]/, '')
        parent.element('span', label, class: 'control-label')
      end

      def _mk_select_(parent, umem, uid)
        span = parent.enclose('span', class: 'center')
        sel = span.enclose('select', name: uid, onchange: 'seldv(this)')
        sel.element('option', '--select--')
        umem.each do |id|
          label = @idx[id][:label] || id
          sel.element('option', label, value: id)
        end
        self
      end

      def _check_group(gid = nil)
        return if @gdb.key?(gid)
        cmd_err(@gdb.map { |k, v| Msg.itemize(k, v[:caption]) }.join("\n"))
      end
    end

    if __FILE__ == $PROGRAM_NAME
      opt = GetOpts.new('[id] [grp]') do |_o, args|
        @dbi = Ins::Db.new.get(args.shift)
        args
      end
      opt.getarg('[id] (ctl)') do |_o, args|
        puts Control.new(@dbi, args)
      end
    end
  end
end
