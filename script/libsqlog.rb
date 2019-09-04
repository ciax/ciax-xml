#!/usr/bin/env ruby
# For sqlite3
require 'libsqlogsv'

# CIAX-XML
module CIAX
  # Generate SQL command string
  module SqLog
    # Table create using @stat.keys
    class Table
      include Msg
      attr_reader :tid, :stat, :tname
      def initialize(layer, stat)
        @layer = layer
        @stat = type?(stat, Varx)
        @id = stat[:id]
        @tid = "#{@stat.type}_#{@stat[:data_ver]}"
        @tname = @stat.type.capitalize
        verbose { "Initiate Table '#{@tid}'" }
      end

      def create
        key = ['time', *__expand.keys].uniq.join("','")
        verbose { "Create ('#{key}')" }
        "create table #{@tid} ('#{key}',primary key(time));"
      end

      def add_field(key) # returns String
        "alter table #{@tid} add column #{key};"
      end

      def insert
        kary = []
        vary = []
        __expand.each do |k, v|
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

      def __expand
        val = { 'time' => @stat[:time] }
        @stat[:data].keys.reject { |k| /type/ =~ k.to_s }.each do |k|
          v = @stat[:data][k]
          if v.is_a? Array
            __rec_expand(k, v, val)
          else
            val[k.to_s] = v
          end
        end
        val
      end

      def __rec_expand(k, v, val)
        v.size.times do |i|
          case v[i]
          when Enumerable
            __rec_expand("#{k}:#{i}", v[i], val)
          else
            val["#{k}:#{i}"] = v[i]
          end
        end
        val
      end
    end

    if __FILE__ == $PROGRAM_NAME
      require 'libappstat'
      Opt::Get.new('[id]') do |_opt, args|
        dbi = Ins::Db.new.get(args.shift)
        stat = App::Status.new(dbi).ext_local.ext_file
        tbl = Table.new('app', stat)
        warn stat
        puts tbl.create
        puts tbl.insert
      end
    end
  end
end
