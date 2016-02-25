#!/usr/bin/ruby
require 'libappsym'

# View is not used for computing, just for apperance for user.
# So the convert process (upd_view) will be included in to_v
# Updated at to_v.
module CIAX
  # Application Layer
  module App
    # Hash of App Groups
    class View < Hashx
      def initialize(stat)
        super()
        @stat = type?(stat, Status)
        adbs = type?(@stat.dbi, Dbi)[:status]
        @group = adbs[:group]
        @index = adbs[:index].dup
        @index.update(adbs[:alias]) if adbs.key?(:alias)
        # Just additional data should be provided
        %i(data class msg).each { |key| stat[key] ||= {} }
        upd_view
      end

      # For Shell raw mode
      def to_r
        @stat.to_r
      end

      def to_csv
        upd_view
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
        upd_view
        cm = Hash.new(2).update('active' => 5, 'alarm' => 1, 'warn' => 3, 'hide' => 0)
        lines = []
        values.each do|v|
          cap = v[:caption]
          lines << ' ***' + colorize(cap, 10) + '***' unless cap.empty?
          lines.concat(v[:lines].map do|ele|
            '  ' + ele.values.map do|val|
              c = cm[val[:class]] + 8
              '[' + colorize(val[:label], 14) + ':' + colorize(val[:msg], c) + ']'
            end.join(' ')
          end)
        end
        lines.join("\n")
      end

      def to_s
        @vmode == :c ? to_csv : super
      end

      private

      def upd_view
        self['gtime'] = { caption: '', lines: [hash = {}] }
        hash[:time] = { label: 'TIMESTAMP', msg: Msg.date(@stat[:time]) }
        hash['elapsed'] = { label: 'ELAPSED', msg: Msg.elps_date(@stat[:time]) }
        @group.each do|k, gdb|
          cap = gdb[:caption] || next
          self[k] = { caption: cap, lines: [] }
          col = gdb[:column] || 1
          gdb[:members].each_slice(col.to_i) do|hline|
            hash = {}
            hline.each do|id|
              h = hash[id] = { label: @index[id][:label] || id.upcase }
              h[:msg] = @stat[:msg][id] || @stat[:data][id]
              h[:class] = @stat[:class][id] if @stat[:class].key?(id)
            end
            self[k][:lines] << hash
          end
        end
        self
      end
    end

    if __FILE__ == $PROGRAM_NAME
      require 'libinsdb'
      opt = GetOpts.new('rc', c: 'CSV output')
      begin
        stat = Status.new
        view = View.new(stat)
        stat.ext_file if STDIN.tty?
        stat.ext_sym.upd
        view.vmode(:c) if opt[:c]
        puts view
      rescue InvalidID
        Msg.usage '(opt) [site] | < status_file'
      end
    end
  end
end
