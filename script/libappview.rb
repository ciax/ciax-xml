#!/usr/bin/env ruby
require 'libappstat'

# View is separated from Status.
# View is not used for computing, just for apperance for user.
# Some information is added from Dbx::Item
# So the convert process (upd) will be included in to_v
# Updated at to_v.
module CIAX
  # Application Layer
  module App
    # Hash of App Status Groups
    class View < Upd
      CM = Hash.new(2).update(active: 5, alarm: 1, warn: 3, hide: 0)
      def initialize(stat)
        super()
        @stat = type?(stat, Status)
        adbs = type?(@stat.dbi, Dbx::Item)[:status]
        @group = adbs[:group]
        @index = adbs[:index].dup
        @index.update(adbs[:alias]) if adbs.key?(:alias)
        # Just additional data should be provided
        ___init_upd_procs
      end

      def to_csv
        upd
        @group.values.each_with_object('') do |gdb, str|
          cap = gdb[:caption] || next
          gdb[:members].each do |id|
            label = @index[id][:label]
            str << "#{cap},#{label},#{@stat.get(id)}\n"
          end
        end
      end

      def to_v
        upd
        values.flat_map do |v|
          next unless v.is_a? Hash
          lns = ___view_lines(v[:lines])
          (cap = v[:caption]).empty? ? lns : lns.unshift(___mk_cap(cap))
        end.compact.join("\n")
      end

      def to_o
        @stat.to_r
      end

      private

      def ___init_upd_procs
        @elps = Elapsed.new(@stat)
        @upd_procs.append(self, :view) do
          self['gtime'] = { caption: '', lines: [hash = {}] }
          hash[:time] = { label: 'TIMESTAMP', msg: date(@stat[:time]) }
          hash[:elapsed] = { label: 'ELAPSED', msg: @elps }
          ___view_groups
        end
      end

      def ___view_groups
        @group.each do |k, gdb|
          cap = gdb[:caption] || next
          g = self[k] = { caption: cap, lines: [] }
          ___upd_members(gdb[:members], gdb[:column] || 1, g[:lines])
        end
      end

      def ___view_lines(lines)
        lines.map do |ele|
          '  ' + ele.values.map do |val|
            cls = (val[:class] || '').to_sym
            lbl = colorize(val[:label], 14)
            msg = colorize(val[:msg], CM[cls] + 8)
            format('[%s:%s]', lbl, msg)
          end.join(' ')
        end
      end

      def ___upd_members(members, col, lines)
        members.each_slice(col.to_i) do |hline|
          lines << hline.each_with_object({}) do |id, hash|
            ___upd_line(id, hash)
          end
        end
      end

      def ___upd_line(id, hash)
        stc = @stat[:class] || {}
        stm = @stat[:msg] || {}
        cls = stc[id] if stc.key?(id)
        msg = stm[id] || @stat.get(id)
        lvl = @index[id][:label] || id.upcase
        hash[id] = { label: lvl, msg: msg, class: cls }
      end

      def ___mk_cap(cap)
        ' ***' + colorize(cap, 10) + '***'
      end
    end

    if $PROGRAM_NAME == __FILE__
      require 'libinsdb'
      Opt::Get.new('[site] | < status_file', options: 'rjv') do |opt, args|
        stat = Status.new(args).ext_local.ext_file
        view = View.new(stat)
        puts opt[:v] ? view.to_csv : view.to_s
      end
    end
  end
end
