#!/usr/bin/ruby
require 'libmsg'
# Generate SQL command string
module CIAX
  module SqLog
    # For log simulator
    class Simulator
      include CIAX::Msg
      attr_reader :index, :max
      def initialize(id)
        @cls_color = 1
        @logary = [{}]
        @index = 0
        @sqlcmd = ['sqlite3', ENV['HOME'] + '/.var/sqlog_' + id + '.sq3']
        @tbl = query('.tables').split(/ /).grep(/^stream/).sort.last || fail('No Stream table')
        @total = query("select count(*) from #{@tbl} where dir='rcv';").to_i
        fail('No Line') if @total < 1
      end

      def query(str)
        verbose { "->[#{str}]" }
        IO.popen(@sqlcmd, 'r+') do|f|
          f.puts str
          str = f.gets.chomp
        end
        verbose { "<-[#{str}]" }
        str
      end

      def find_next(str)
        begin
          verbose { 'Search corresponding CMD' }
          sql = "select min(time),cmd from #{@tbl} where time > #{@index} and base64='#{str}';"
          ans = query(sql)
          tim, cmd = ans.split('|')
          verbose { "Matched time is #{tim}" }
          fail if tim.empty?
          @index = tim.to_i
        rescue
          raise("NO record for #{str}") if @index == 0
          @index = 0
          verbose { color('LINE:REWINDED', 3) }
          retry
        end
        verbose { 'Search corresponding RES' }
        sql = "select min(time),count(*),cmd,base64 from #{@tbl} where dir='rcv' and cmd='#{cmd}' and time > #{tim};"
        ans = query(sql)
        tim, count, = ans.split('|')
        verbose { color("LINE:[#{cmd}](#{@total - count.to_i}/#{@total})<#{wait(tim)}>", 2) }
        sql = "select base64 from #{@tbl} where time = #{tim};"
        query(sql)
      end

      def wait(tim)
        dif = (tim.to_i > @index) ? [tim.to_i - @index, 1000].min : 0
        wt = dif.to_f / 1000
        sleep wt
        '%.3f' % wt
      end

      def input
        select([STDIN])
        [STDIN.sysread(1024)].pack('m').split("\n").join('')
      end
    end
  end
end
