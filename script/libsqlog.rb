#!/usr/bin/ruby
# For sqlite3
require 'libthreadx'

# CIAX-XML
module CIAX
  # Generate SQL command string
  module SqLog
    @list = {}

    # @list accessor
    def self.list
      @list
    end

    # Table create using @stat.keys
    class Table
      include Msg
      attr_reader :tid, :stat, :tname
      def initialize(stat)
        @stat = type?(stat, Varx)
        @id = stat[:id]
        @tid = "#{@stat.type}_#{@stat[:ver]}"
        @tname = @stat.type.capitalize
        verbose { "Initiate Table '#{@tid}'" }
      end

      def create
        key = ['time', *expand.keys].uniq.join("','")
        verbose { "Create ('#{key}')" }
        "create table #{@tid} ('#{key}',primary key(time));"
      end

      def add_field(key) # returns String
        "alter table #{@tid} add column #{key};"
      end

      def insert
        kary = []
        vary = []
        expand.each do |k, v|
          kary << k.inspect
          vary << (k == 'time' ? v.to_i : v.inspect)
        end
        verbose { "Update(#{@stat.time_id})" }
        ks = kary.join(',')
        vs = vary.join(',')
        "insert or ignore into #{@tid} (#{ks}) values (#{vs});"
      end

      def start
        'begin;'
      end

      def commit
        'commit;'
      end

      private

      def expand
        val = { 'time' => @stat[:time] }
        @stat[:data].keys.select { |k| /type/ !~ k.to_s }.each do |k|
          v = @stat[:data][k]
          if v.is_a? Array
            rec_expand(k, v, val)
          else
            val[k.to_s] = v
          end
        end
        val
      end

      def rec_expand(k, v, val)
        v.size.times do |i|
          case v[i]
          when Enumerable
            rec_expand("#{k}:#{i}", v[i], val)
          else
            val["#{k}:#{i}"] = v[i]
          end
        end
        val
      end
    end

    # Execute Sql Command to sqlite3
    class Save
      # @< log,tid
      # @ sqlcmd
      include Msg
      def initialize(id)
        @id = id
        base = "sqlog_#{id}"
        @sqlcmd = ['sqlite3', vardir('log') + base + '.sq3']
        @que_sql = Threadx::QueLoop.new('SqLog', 'all', @id, base) do |que|
          _log_save(que)
        end
      end

      # Check table existence (ver=0 is invalid)
      def init_table(stat) # returns self
        tbl = Table.new(stat)
        if stat[:ver].to_i > 0
          create_tbl(tbl)
          real_mode(stat, tbl)
        else
          dummy_mode(stat, tbl)
        end
        self
      end

      # Issue internal command
      def internal(str)
        args = @sqlcmd.join(' ') + ' .' + str
        `#{args}`
      end

      private

      def _log_save(que)
        sql = que.pop
        IO.popen(@sqlcmd, 'w') { |f| f.puts sql }
        verbose { "Saved for '#{sql}'" }
      rescue
        Msg.give_up("Sqlite3 input error\n#{sql}")
      end

      # Create table if no table
      def create_tbl(tbl)
        return if internal('tables').split(' ').include?(tbl.tid)
        @que_sql.push tbl.create
        verbose { "'#{tbl.tid}' is created" }
      end

      def real_mode(stat, tbl)
        # Add to stat.cmt
        stat.cmt_procs << proc { @que_sql.push tbl.insert }
      end

      def dummy_mode(stat, tbl)
        verbose { 'Invalid Version(0): No Log' }
        stat.cmt_procs << proc { verbose { "Dummy Insert\n" + tbl.insert } }
      end
    end

    if __FILE__ == $PROGRAM_NAME
      require 'libstatus'
      GetOpts.new('[id]') do |_opt, args|
        dbi = Ins::Db.new.get(args.shift)
        stat = App::Status.new(dbi).ext_local_file
        tbl = Table.new(stat)
        puts stat
        puts tbl.create
        puts tbl.insert
      end
    end
  end
end
