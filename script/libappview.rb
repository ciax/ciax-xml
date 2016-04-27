#!/usr/bin/ruby
require 'libappsym'

# View is not used for computing, just for apperance for user.
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
        adbs = type?(@stat.dbi, Dbi)[:status]
        @group = adbs[:group]
        @index = adbs[:index].dup
        @index.update(adbs[:alias]) if adbs.key?(:alias)
        # Just additional data should be provided
        %i(data class msg).each { |key| stat.get(key) { Hashx.new } }
        upd
      end

      def to_csv
        upd
        str = ''
        @group.values.each do|gdb|
          cap = gdb[:caption] || next
          gdb[:members].each do|id|
            label = @index[id][:label]
            str << "#{cap},#{label},#{@stat.get(id)}\n"
          end
        end
        str
      end

      def to_v
        upd
        lines = []
        values.each do|v|
          next unless v.is_a? Hash
          cap = v[:caption]
          lines << ' ***' + colorize(cap, 10) + '***' unless cap.empty?
          lines.concat(_view_lines(v[:lines]))
        end
        lines.join("\n")
      end

      def to_o
        @stat.to_r
      end

      def upd
        self['gtime'] = { caption: '', lines: [hash = {}] }
        hash[:time] = { label: 'TIMESTAMP', msg: Msg.date(@stat[:time]) }
        hash[:elapsed] = { label: 'ELAPSED', msg: Msg.elps_date(@stat[:time]) }
        @group.each do|k, gdb|
          cap = gdb[:caption] || next
          lines = []
          self[k] = { caption: cap, lines: lines }
          _upd_members(gdb[:members], gdb[:column] || 1, lines)
        end
        self
      end

      private

      def _view_lines(lines)
        lines.map do|ele|
          '  ' + ele.values.map do|val|
            cls = (val[:class] || '').to_sym
            lbl = colorize(val[:label], 14)
            msg = colorize(val[:msg], CM[cls] + 8)
            format('[%s:%s]', lbl, msg)
          end.join(' ')
        end
      end

      def _upd_members(members, col, lines)
        members.each_slice(col.to_i) do|hline|
          hash = {}
          hline.each { |id| _upd_line(id, hash) }
          lines << hash
        end
      end

      def _upd_line(id, hash)
        stc = @stat[:class]
        msg = @stat[:msg][id] || @stat[:data][id]
        cls = stc[id] if stc.key?(id)
        lvl = @index[id][:label] || id.upcase
        hash[id] = { label: lvl, msg: msg, class: cls }
      end
    end

    if __FILE__ == $PROGRAM_NAME
      require 'libinsdb'
      odb = { c: 'CSV output' }
      GetOpts.new('[site] | < status_file', 'rjc', odb) do |opt|
        stat = Status.new
        view = View.new(stat)
        stat.ext_file if STDIN.tty?
        stat.ext_sym.cmt
        puts opt[:c] ? view.to_csv : view.to_s
      end
    end
  end
end
