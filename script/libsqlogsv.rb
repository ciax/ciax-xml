#!/usr/bin/env ruby
# For sqlite3
require 'libthreadx'

# CIAX-XML
module CIAX
  # Generate SQL command string
  module SqLog
    @dic = {}

    # @dic accessor
    def self.list
      @dic
    end

    def self.new(id)
      @dic[id] ||= Save.new(id)
    end
    # Execute Sql Command to sqlite3
    class Save
      # @< log,tid
      # @ sqlcmd
      include Msg
      def initialize(id)
        @id = id
        @sqlcmd = ['sqlite3', vardir('log') + "sqlog_#{id}.sq3"]
        @que = Threadx::QueLoop.new('SqLog', 'all', @id) do |que|
          ___log_save(que)
        end.que
      end

      # Check table existence (ver=0 is invalid)
      def init_table(layer, stat) # returns self
        tbl = Table.new(layer, stat)
        if stat[:data_ver].to_i > 0
          ___create_tbl(tbl)
          ___real_mode(stat, tbl)
        else
          ___dummy_mode(stat, tbl)
        end
        self
      end

      # Issue internal command
      def internal(str)
        args = @sqlcmd.join(' ') + ' .' + str
        `#{args}`
      end

      private

      # FIFO
      def ___log_save(que)
        sql = que.shift
        IO.popen(@sqlcmd, 'w') { |f| f.puts sql }
        verbose { "Saved for '#{sql}'" }
      rescue
        give_up("Sqlite3 input error\n#{sql}")
      end

      # Create table if no table
      def ___create_tbl(tbl)
        return if internal('tables').split(' ').include?(tbl.tid)
        @que.push tbl.create
        verbose { "'#{tbl.tid}' is created" }
      end

      def ___real_mode(stat, tbl)
        # Add to stat.cmt
        stat.cmt_procs.append(self, :sqlog, 3) { @que.push tbl.insert }
      end

      def ___dummy_mode(stat, tbl)
        verbose { 'Invalid Version(0): No Log' }
        stat.cmt_procs.append(self, :sqlog, 2) do
          verbose { "Dummy Insert\n" + tbl.insert }
        end
      end
    end
  end
end
