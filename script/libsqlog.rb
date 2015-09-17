#!/usr/bin/ruby
# For sqlite3
require "libmsg"
require "thread"

# Generate SQL command string
module CIAX
  module SqLog;NsColor=1
    # Table create using @stat.keys
    class Table
      attr_reader :tid,:stat,:tname
      include Msg
      def initialize(stat)
        @cls_color=14
        @stat=type?(stat,Datax)
        @tid="#{@stat.type}_#{@stat['ver']}"
        @tname=@stat.type.capitalize
        verbose("Initialize Table '#{@tid}'")
      end

      def create
        key=['time',*expand.keys].uniq.join("','")
        verbose("Create ('#{key}')")
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
        verbose("Update(#{@stat['time']})")
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
        @stat.keys.each{|k|
          next if /type/ =~ k
          case v=@stat.get(k)
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
      def initialize(id,layer=nil)
        @cls_color=10
        @sqlcmd=["sqlite3",vardir("log")+"sqlog_#{id}.sq3"]
        @queue=Queue.new
        verbose("Initialize '#{id}' on #{layer}")
        ThreadLoop.new("SqLog(#{layer}:#{id})",13){
          sqlary=['begin;']
          begin
            sqlary << @queue.pop
          end until @queue.empty?
          sqlary << 'commit;'
          IO.popen(@sqlcmd,'w'){|f|
            sqlary.each{|sql|
              begin
                f.puts sql
                verbose("Saved for '#{sql}'")
              rescue
                Msg.abort("Sqlite3 input error\n#{sql}")
              end
            }
          }
        }
      end

      # Check table existence (ver=0 is invalid)
      def add_table(stat)
        sqlog=Table.new(stat)
        if $opt['e'] && stat['ver'].to_i > 0
          # Create table if no table
          unless internal("tables").split(' ').include?(sqlog.tid)
            @queue.push sqlog.create
            verbose("Initialize '#{sqlog.tid}' is created")
          end
          # Add to stat.upd
          stat.post_upd_procs << proc{
            verbose("Propagate Save#upd -> upd")
            @queue.push sqlog.upd
          }
        else
          verbose("Initialize: invalid Version(0): No Log")
          stat.post_upd_procs << proc{
            verbose("Propagate Save#upd -> upd(Dryrun)")
            verbose("Insert",sqlog.upd)
          }
        end
        self
      end

      # Issue internal command
      def internal(str)
        args=@sqlcmd.join(' ')+" ."+str
        `#{args}`
      end
    end

    # For log simulator
    class LogRing
      include CIAX::Msg
      attr_reader :index,:max
      def initialize(id)
        @cls_color=1
        @logary=[{}]
        @index=0
        @sqlcmd=["sqlite3",ENV['HOME']+"/.var/sqlog_"+id+".sq3"]
        @tbl=query('.tables').split(/ /).grep(/^stream/).sort.last || raise("No Stream table")
        @total=query("select count(*) from #@tbl where dir='rcv';").to_i
        raise("No Line") if @total < 1
      end

      def query(str)
        verbose("->[#{str}]")
        IO.popen(@sqlcmd,'r+'){|f|
          f.puts str
          str=f.gets.chomp
        }
        verbose("<-[#{str}]")
        str
      end

      def find_next(str)
        begin
          verbose("Search corresponding CMD")
          sql="select min(time),cmd from #@tbl where time > #@index and base64='#{str}';"
          ans=query(sql)
          tim,cmd=ans.split('|')
          verbose("Matched time is #{tim}")
          raise if tim.empty?
          @index=tim.to_i
        rescue
          raise("NO record for #{str}") if @index==0
          @index=0
          verbose(color("LINE:REWINDED",3))
          retry
        end
        verbose("Search corresponding RES")
        sql="select min(time),count(*),cmd,base64 from #@tbl where dir='rcv' and cmd='#{cmd}' and time > #{tim};"
        ans=query(sql)
        tim,count,base64=ans.split('|')
        verbose(color("LINE:[#{cmd}](#{@total-count.to_i}/#{@total})<#{wait(tim)}>",2))
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

    if __FILE__ == $0
      require "libappexe"
      GetOpts.new
      id=ARGV.shift
      ARGV.clear
      begin
        dbi=Ins::Db.new.get(id)
        stat=App::Status.new.set_dbi(dbi).ext_file
        sqlog=Table.new(stat)
        puts stat
        puts sqlog.create
        puts sqlog.upd
      rescue InvalidID
        Msg.usage "[id]"
      end
    end
  end
end
