#!/usr/bin/ruby
require "libmsg"
require "thread"

# SubModule for App::Sv
# *Command stream(Send)
#  send() takes frame cmdary(Array of Array) in block
#  -> Inbuf[priority]
#  -> Accept or Reject
#  -> flush -> Queue
#
# *Command stream(Recieve)
#  recv()
#  Queue -> Outbuf until Queue is empty
#  -> provide single frame args(Array) as it is called
#  (stack if Queue is empty)
module CIAX
  class Buffer
    include Msg
    # svst: Server Status
    def initialize(svst={})
      @svst=type?(svst,Hash)
      #element of @q is bunch of frm args corresponding an appcmd
      @q=Queue.new
      @tid=nil
      @flush_proc=proc{}
      @send_proc=proc{}
      clear
    end

    def send_proc
      @send_proc=proc{|ent| yield ent}
      self
    end

    # Send frm command batch (ary of ary)
    def send(n=1,ent)
      type?(ent,Entity)
      clear if n == 0
      batch=@send_proc.call(ent)
      #batch is frm batch (ary of ary)
      unless batch.empty?
        @svst['isu']=true
        @q.push([n,batch])
      end
      self
    end

    def recv_proc
      @tid=Thread.new{
        tc=Thread.current
        tc[:name]="Buffer Thread(#{@svst['layer']}:#{@svst['id']})"
        tc[:color]=10
        Thread.pass
        loop{
          begin
            sort(*@q.shift)
            while args=pick
              yield args
            end
            flush
          rescue
            fatal("Buffer","#{$!.to_s.chomp} in Buffer Thread")
            clear
          end
        }
      }
      self
    end

    def flush_proc
      @flush_proc=proc{|ent| yield ent}
      self
    end

    def alive?
      @tid && @tid.alive?
    end

    private
    def flush
      verbose("Buffer","SUB:Waiting")
      # @q can not be empty depending on @flush_proc
      @flush_proc.call(self)
      @svst['isu']=false if @q.empty?
    end

    #batch is command array (ary of ary)
    def sort(p,batch)
      verbose("Buffer","SUB:Recieve [#{batch}] with priority[#{p}]")
      (@outbuf[p]||=[]).concat(batch)
      i=-1
      @outbuf.map{|o|
        verbose("Buffer","SUB:Outbuf(#{i+=1}) is [#{o}]\n")
      }
    end

    # Remove duplicated args and pop one
    def pick
      args=nil
      @outbuf.size.times{|i|
        if args
          @outbuf[i].delete(args)
        else
          args=@outbuf[i].shift
        end
      }
      args
    end

    def clear
      @issue=false
      @outbuf=[[],[],[]]
      @q.clear
      @tid && @tid.run
    end
  end
end
