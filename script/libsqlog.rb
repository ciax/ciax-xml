#!/usr/bin/ruby
# For sqlite3
require "libmsg"
require "thread"

# Generate SQL command string
module CIAX
  module SqLog
    class Upd
      attr_reader :tid,:stat
      include Msg
      def initialize(stat,ver=nil)
        @ver_color=9
        @stat=type?(stat,Hash)
        ver||=@stat['ver'].to_i
        @tid="#{@stat['type']}_#{ver}"
        verbose("SqLog","Init/Table '#{@tid}'")
      end

      def create
        key=['time',*expand.keys].uniq.join("','")
        verbose("SqLog","create ('#{key}')")
        "create table #{@tid} ('#{key}',primary key(time));"
      end

      def add_field(key)
        "alter table #{@tid} add column #{key};"
      end

      def upd
        kary=[]
        vary=[]
        expand.each{|k,v|
          kary << k.inspect
          vary << (k == 'time' ? v.to_i : v.inspect)
        }
        verbose("SqLog","Update(#{@stat['time']}):[#{@stat['id']}/#{@tid}]")
        "insert or ignore into #{@tid} (#{kary.join(',')}) values (#{vary.join(',')});"
      end

      def start
        "begin;"
      end

      def commit
        "commit;"
      end

      private
      def expand
        val={'time'=>@stat['time']}
        @stat.data.each{|k,v|
          next if /type/ =~ k
          case v
          when Array
            rec_expand(k,v,val)
          else
            val[k]=v
          end
        }
        val
      end

      def rec_expand(k,v,val)
        v.size.times{|i|
          case v[i]
          when Enumerable
            rec_expand("#{k}:#{i}",v[i],val)
          else
            val["#{k}:#{i}"]=v[i]
          end
        }
        val
      end
    end

    # Execute Sql Command to sqlite3
    class Save
      # @< log,tid
      # @ sqlcmd
      include Msg
      def initialize(id)
        @sqlcmd=["sqlite3",VarDir+"/sqlog_"+id+".sq3"]
        @queue=Queue.new
        @ver_color=9
        Threadx.new("SqLog Thread(#{id})",10){
          verbose("SqLog","Init/Server '#{id}'")
          loop{
            sqlary=['begin;']
            begin
              sqlary << @queue.pop
            end until @queue.empty?
            sqlary << 'commit;'
            IO.popen(@sqlcmd,'w'){|f|
              sqlary.each{|sql|
                begin
                  f.puts sql
                  verbose("SqLog","Saved for '#{sql}'")
                rescue
                  Msg.abort("Sqlite3 input error\n#{sql}")
                end
              }
            }
          }
        }
      end

      # Check table existence
      def add_table(stat)
        sqlog=Upd.new(stat)
        unless internal("tables").split(' ').include?(sqlog.tid)
          @queue.push sqlog.create
          verbose("SqLog","Init/Table '#{sqlog.tid}' is created")
        end
        stat.upd_procs << proc{
          @queue.push sqlog.upd
        }
        self
      end

      # Issue internal command
      def internal(str)
        args=@sqlcmd.join(' ')+" ."+str
        `#{args}`
      end
    end

    class LogRing
      include CIAX::Msg
      attr_reader :index,:max
      def initialize(id)
        @logary=[{}]
        @index=0
        @sqlcmd=["sqlite3",ENV['HOME']+"/.var/sqlog_"+id+".sq3"]
        @tbl=query('.tables').split(/ /).grep(/^stream/).sort.last || raise("No Stream table")
        @total=query("select count(*) from #@tbl where dir='rcv';").to_i
        raise("No Line") if @total < 1
        @ver_color=1
      end

      def query(str)
        verbose("DevSim","->[#{str}]")
        IO.popen(@sqlcmd,'r+'){|f|
          f.puts str
          str=f.gets.chomp
        }
        verbose("DevSim","<-[#{str}]")
        str
      end

      def find_next(str)
        begin
          verbose("DevSim","Search corresponding CMD")
          sql="select min(time),cmd from #@tbl where time > #@index and base64='#{str}';"
          ans=query(sql)
          tim,cmd=ans.split('|')
          raise if tim.empty?
          @index=tim.to_i
        rescue
          raise("NO record for #{str}") if @index==0
          @index=0
          verbose("DevSim",color("LINE:REWINDED",3))
          retry
        end
        verbose("DevSim","Search corresponding RES")
        sql="select min(time),count(*),cmd,base64 from #@tbl where dir='rcv' and cmd='#{cmd}' and time > #{tim};"
        ans=query(sql)
        tim,count,base64=ans.split('|')
        verbose("DevSim",color("LINE:[#{cmd}](#{@total-count.to_i}/#{@total})<#{wait(tim)}>",2))
        sql="select base64 from #@tbl where time = #{tim};"
        query(sql)
      end

      def wait(tim)
        dif=(tim.to_i > @index) ? [tim.to_i-@index,1000].min : 0
        wt=dif.to_f/1000
        sleep wt
        '%.3f' % wt
      end

      def input
        select([STDIN])
        [STDIN.sysread(1024)].pack("m").split("\n").join('')
      end

    end
  end

  if __FILE__ == $0
    require "liblocdb"
    require "libstatus"
    id=ARGV.shift
    ARGV.clear
    begin
      adb=Loc::Db.new.set(id)[:app]
      stat=App::Status.new.ext_file(adb['site_id']).load
      sqlog=SqLog::Upd.new(stat)
      puts sqlog.create
      puts sqlog.upd
    rescue InvalidID
      Msg.usage "[id]"
    end
    exit
  end
end
