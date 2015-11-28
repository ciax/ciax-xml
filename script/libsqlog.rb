#!/usr/bin/ruby
# For sqlite3
require 'libmsg'
require 'libvarx'
require 'thread'

# CIAX-XML
module CIAX
  # Generate SQL command string
  module SqLog
    # Table create using @stat.keys
    class Table
      attr_reader :tid, :stat, :tname
      include Msg
      def initialize(stat)
        @cls_color = 14
        @stat = type?(stat, Varx)
        @tid = "#{@stat.type}_#{@stat['ver']}"
        @tname = @stat.type.capitalize
        verbose { "Initialize Table '#{@tid}'" }
      end

      def create
        key = ['time', *expand.keys].uniq.join("','")
        verbose { "Create ('#{key}')" }
        "create table #{@tid} ('#{key}',primary key(time));"
      end

      def add_field(key)
        "alter table #{@tid} add column #{key};"
      end

      def upd
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
        val = { 'time' => @stat['time'] }
        @stat.keys.select { |k| /type/ !~ k }.each do |k|
          v = @stat.get(k)
          if v.is_a? Array
            rec_expand(k, v, val)
          else
            val[k] = v
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
      def initialize(id, layer = nil)
        @cls_color = 10
        @sqlcmd = ['sqlite3', vardir('log') + "sqlog_#{id}.sq3"]
        @queue = Queue.new
        verbose { "Initialize '#{id}' on #{layer}" }
        ThreadLoop.new("SqLog(#{layer}:#{id})", 13) { server }
      end

      # Check table existence (ver=0 is invalid)
      def add_table(stat)
        sqlog = Table.new(stat)
        if OPT[:e] && stat['ver'].to_i > 0
          create_tbl(sqlog)
          real_mode(stat, sqlog)
        else
          dummy_mode(stat, sqlog)
        end
        self
      end

      # Issue internal command
      def internal(str)
        args = @sqlcmd.join(' ') + ' .' + str
        `#{args}`
      end

      private

      def server
        IO.popen(@sqlcmd, 'w') do |f|
          get_que(['begin;']).each do |sql|
            begin
              f.puts sql
              verbose { "Saved for '#{sql}'" }
            rescue
              Msg.give_up("Sqlite3 input error\n#{sql}")
            end
          end
        end
      end

      def get_que(sqlary)
        loop do
          sqlary << @queue.pop
          break if @queue.empty?
        end
        sqlary << 'commit;'
      end

      # Create table if no table
      def create_tbl(sqlog)
        return if internal('tables').split(' ').include?(sqlog.tid)
        @queue.push sqlog.create
        verbose { "Initialize '#{sqlog.tid}' is created" }
      end

      def real_mode(stat, sqlog)
        # Add to stat.upd
        stat.post_upd_procs << proc { @queue.push sqlog.upd }
      end

      def dummy_mode(stat, sqlog)
        verbose { 'Initialize: invalid Version(0): No Log' }
        stat.post_upd_procs << proc { verbose { "Insert\n" + sqlog.upd } }
      end
    end
  end

  if __FILE__ == $PROGRAM_NAME
    require 'libappexe'
    id = ARGV.shift
    ARGV.clear
    begin
      dbi = Ins::Db.new.get(id)
      stat = App::Status.new.setdbi(dbi).ext_file
      sqlog = Table.new(stat)
      puts stat
      puts sqlog.create
      puts sqlog.upd
    rescue InvalidID
      Msg.usage '[id]'
    end
  end
end
