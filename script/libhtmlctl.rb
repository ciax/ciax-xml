#!/usr/bin/env ruby
require 'libhtmltbl'
# CIAX-XML
module CIAX
  # HTML Table generation
  module HtmlTbl
    # Html Control
    class Control < Status
      def initialize(dbi, grpary = [])
        super(dbi)
        ___mk_ctl_grp(grpary)
        return unless @dbi[:watch] && !grpary.include?('-')
        _elem_button(@ctltd, 'stop')
      end

      private

      def ___mk_ctl_grp(grpary)
        __check_group if grpary.empty?
        grpary.each do |gid|
          next if gid == '-'
          __check_group(gid)
          tbody = _mk_tbody('Control ' + @gdb[gid][:caption])
          ___mk_ctl_column(gid, tbody)
        end
        self
      end

      def ___mk_ctl_column(gid, tbody)
        return unless @udb
        member = @gdb[gid][:units] || return
        member.sort.each_slice(3) do |uary|
          td = tbody.enclose('tr').enclose('td', class: 'item')
          ___mk_ctl_line(td, uary)
        end
      end

      def ___mk_ctl_line(td, uary)
        uary.each do |uid|
          next if ___mk_ctl_unit(td, uid)
          errary = @udb.map { |k, v| itemize(k, v[:label]) }
          errary.unshift('Wrong CTL Unit')
          give_up(errary.join("\n"))
        end
        self
      end

      def ___mk_ctl_unit(parent, uid)
        return unless @udb.key?(uid)
        uat = @udb[uid]
        ___mk_label(parent, uat)
        umem = uat[:members]
        ___mk_select(parent, umem, uid)
      end

      def ___mk_label(parent, atrb)
        return unless atrb[:label]
        label = atrb[:label].gsub(/\[.*\]/, '')
        parent.element('span', label, class: 'control-label')
      end

      def ___mk_select(parent, umem, uid)
        span = parent.enclose('span', class: 'center')
        sel = span.enclose('select', name: uid, onchange: 'seldv(this)')
        sel.element('option', '--select--')
        umem.each do |id|
          label = @idx[id][:label] || id
          sel.element('option', label, value: id)
        end
        self
      end

      def __check_group(gid = nil)
        return if @gdb.key?(gid)
        cmd_err { @gdb.map { |k, v| Msg.itemize(k, v[:caption]) } }
      end
    end

    if __FILE__ == $PROGRAM_NAME
      Opt::Get.new('[id] [grp]') do |opt, args|
        dbi = Ins::Db.new.get(args.shift)
        opt.getarg('[id] (ctl)') do |_o, ar|
          puts Control.new(dbi, ar)
        end
      end
    end
  end
end
