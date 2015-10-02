#!/usr/bin/ruby
# For sqlite3
require 'libmsg'
require 'thread'

# Generate SQL command string
module CIAX
  module SqLog; NsColor = 1
    # Table create using @stat.keys
               class Table
                 attr_reader :tid, :stat, :tname
                 include Msg
                 def initialize(stat)
                   @cls_color = 14
                   @stat = type?(stat, Datax)
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
                   expand.each{|k, v|
                     kary << k.inspect
                     vary << (k == 'time' ? v.to_i : v.inspect)
                   }
                   verbose { "Update(#{@stat['time']})" }
                   "insert or ignore into #{@tid} (#{kary.join(',')}) values (#{vary.join(',')});"
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
                   @stat.keys.each{|k|
                     next if /type/ =~ k
                     case v = @stat.get(k)
                     when Array
                       rec_expand(k, v, val)
                     else
                       val[k] = v
                     end
                   }
                   val
                 end

                 def rec_expand(k, v, val)
                   v.size.times{|i|
                     case v[i]
                     when Enumerable
                       rec_expand("#{k}:#{i}", v[i], val)
                     else
                       val["#{k}:#{i}"] = v[i]
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
                 def initialize(id, layer = nil)
                   @cls_color = 10
                   @sqlcmd = ['sqlite3', vardir('log') + "sqlog_#{id}.sq3"]
                   @queue = Queue.new
                   verbose { "Initialize '#{id}' on #{layer}" }
                   ThreadLoop.new("SqLog(#{layer}:#{id})", 13){
                     sqlary = ['begin;']
                     loop{
                       sqlary << @queue.pop
                       break if @queue.empty?
                     }
                     sqlary << 'commit;'
                     IO.popen(@sqlcmd, 'w'){|f|
                       sqlary.each{|sql|
                         begin
                           f.puts sql
                           verbose { "Saved for '#{sql}'" }
                         rescue
                           Msg.abort("Sqlite3 input error\n#{sql}")
                         end
                       }
                     }
                   }
                 end

                 # Check table existence (ver=0 is invalid)
                 def add_table(stat)
                   sqlog = Table.new(stat)
                   if $opt['e'] && stat['ver'].to_i > 0
                     # Create table if no table
                     unless internal('tables').split(' ').include?(sqlog.tid)
                       @queue.push sqlog.create
                       verbose { "Initialize '#{sqlog.tid}' is created" }
                     end
                     # Add to stat.upd
                     stat.post_upd_procs << proc{
                       verbose { 'Propagate Save#upd -> upd' }
                       @queue.push sqlog.upd
                     }
                   else
                     verbose { 'Initialize: invalid Version(0): No Log' }
                     stat.post_upd_procs << proc{
                       verbose { 'Propagate Save#upd -> upd(Dryrun)' }
                       verbose { ['Insert', sqlog.upd] }
                     }
                   end
                   self
                 end

                 # Issue internal command
                 def internal(str)
                   args = @sqlcmd.join(' ') + ' .' + str
                   `#{args}`
                 end
               end

               if __FILE__ == $0
                 require 'libappexe'
                 GetOpts.new
                 id = ARGV.shift
                 ARGV.clear
                 begin
                   dbi = Ins::Db.new.get(id)
                   stat = App::Status.new.set_dbi(dbi).ext_save.ext_load
                   sqlog = Table.new(stat)
                   puts stat
                   puts sqlog.create
                   puts sqlog.upd
                 rescue InvalidID
                   Msg.usage '[id]'
                 end
               end
  end
end
