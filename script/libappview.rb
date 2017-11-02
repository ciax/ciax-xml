#!/usr/bin/ruby
require 'libappsym'

# View is not used for computing, just for apperance for user.
# Some information is added from Dbi
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
        _init_upd_proc
      end

      def to_csv
        upd
        str = ''
        @group.values.each do |gdb|
          cap = gdb[:caption] || next
          gdb[:members].each do |id|
            label = @index[id][:label]
            str << "#{cap},#{label},#{@stat.get(id)}\n"
          end
        end
        str
      end

      def to_v
        upd
        lines = []
        values.each do |v|
          next unless v.is_a? Hash
          cap = v[:caption]
          lines << ' ***' + colorize(cap, 10) + '***' unless cap.empty?
          lines.concat(_view_lines_(v[:lines]))
        end
        lines.join("\n")
      end

      def to_o
        @stat.to_r
      end

      private

      def _init_upd_proc
        @upd_procs << proc do
          @stat.upd
          self['gtime'] = { caption: '', lines: [hash = {}] }
          hash[:time] = { label: 'TIMESTAMP', msg: date(@stat[:time]) }
          hash[:elapsed] = { label: 'ELAPSED', msg: elps_date(@stat[:time]) }
          _view_groups_
        end
      end

      def _view_groups_
        @group.each do |k, gdb|
          cap = gdb[:caption] || next
          lines = []
          self[k] = { caption: cap, lines: lines }
          _upd_members_(gdb[:members], gdb[:column] || 1, lines)
        end
      end

      def _view_lines_(lines)
        lines.map do |ele|
          '  ' + ele.values.map do |val|
            cls = (val[:class] || '').to_sym
            lbl = colorize(val[:label], 14)
            msg = colorize(val[:msg], CM[cls] + 8)
            format('[%s:%s]', lbl, msg)
          end.join(' ')
        end
      end

      def _upd_members_(members, col, lines)
        members.each_slice(col.to_i) do |hline|
          hash = {}
          hline.each { |id| _upd_line_(id, hash) }
          lines << hash
        end
      end

      def _upd_line_(id, hash)
        stc = @stat[:class]
        msg = @stat[:msg][id] || @stat[:data][id]
        cls = stc[id] if stc.key?(id)
        lvl = @index[id][:label] || id.upcase
        hash[id] = { label: lvl, msg: msg, class: cls }
      end
    end

    if __FILE__ == $PROGRAM_NAME
      require 'libinsdb'
      odb = { options: 'rj', c: 'CSV output' }
      GetOpts.new('[site] | < status_file', odb) do |opt, args|
        stat = Status.new(args.shift)
        view = View.new(stat)
        stat.ext_local_file if STDIN.tty?
        stat.ext_local_sym.cmt
        puts opt[:c] ? view.to_csv : view.to_s
      end
    end
  end
end
