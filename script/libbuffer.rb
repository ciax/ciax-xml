#!/usr/bin/ruby
require "libdatax"
require "libthreadx"

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
#
# *Command Priority
#  0:Interrupt
#  1:User Input
#  2:Event Driven
#  3:Periodic Update

module CIAX
  class Buffer < Datax
    # svst: Server Status
    def initialize(svst={})
      super('issue',{'pri' => '','cid' => '','src' => ''})
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
    def send(n=1,ent,src)
      type?(ent,Entity)
      clear if n == 0
      batch=@send_proc.call(ent)
      #batch is frm batch (ary of ary)
      @data.update('time'=>now_msec,'pri' => n,'cid' => ent.id,'src'=>src)
      unless batch.empty?
        @svst['isu']=true
        @q.push(:pri => n,:batch => batch,:src => src)
      end
      self
    ensure
      post_upd
    end

    def recv_proc
      @tid=ThreadLoop.new("Buffer",12){
        begin
          rcv=@q.shift
          sort(rcv[:pri],rcv[:batch])
          while args=pick
            yield args,rcv[:src]
          end
          flush
        rescue
          clear
          errmsg
        end
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

    def flush
      verbose("Buffer","SUB:Waiting")
      # @q can not be empty depending on @flush_proc
      @flush_proc.call(self)
      @svst['isu']=false if @q.empty?
      self
    end

    private
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
      @svst['isu']=false
      @outbuf=[[],[],[]]
      @q.clear
      @tid && @tid.run
    end
  end
end
