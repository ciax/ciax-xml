#!/usr/bin/ruby
require "libprompt"
require "libthreadx"
require "libgroup"

# SubModule for App::Sv
# *Command stream(Send)
#  send() takes frame batch(Array of Args) in block
#  -> Inbuf[priority]
#  -> Accept or Reject
#  -> Queue
#
# *Command stream(Recieve)
#  recv()
#  Queue -> Outbuf until Queue is empty
#  -> provide single frame args(Array) as it is called
#  -> flush as Queue becomes empty
#  (wait for command input in Queue) -> loop
#
# *Command Priority
#  0:Interrupt
#  1:User Input
#  2:Event Driven
#  3:Periodic Update

module CIAX
  class Buffer < Varx
    # site_stat: Server Status
    def initialize(id,ver,site_stat={})
      super('issue',id,ver)
      update('pri' => '','cid' => '','src' => '')
      @site_stat=type?(site_stat,Prompt)
      #element of @q is bunch of frm args corresponding an appcmd
      @q=Queue.new
      @tid=nil
      @flush_proc=proc{}
      @send_proc=proc{}
      @recv_proc=proc{}
      clear
    end

    def send_proc
      @send_proc=proc{|ent| yield ent}
      self
    end

    def recv_proc
      @recv_proc=proc{|args,src| yield args,src}
      self
    end

    # Send frm command batch (ary of ary)
    def send(ent,n=1,src='local')
      type?(ent,Command::Entity)
      clear if n == 0
      batch=@send_proc.call(ent)
      #batch is frm batch (ary of ary)
      update('time'=>now_msec,'pri' => n,'cid' => ent.id,'src'=>src)
      unless batch.empty?
        @site_stat.set('isu')
        @q.push(:pri => n,:batch => batch,:src => src)
      end
      self
    ensure
      post_upd
    end

    def server
      @tid=ThreadLoop.new("Buffer(#{self['id']})",12){
        begin
          rcv=@q.shift
          sort(rcv[:pri],rcv[:batch])
          while args=pick
            @recv_proc.call(args,rcv[:src])
          end
          flush
        rescue
          clear
          alert($!.to_s)
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
      verbose("SUB:Waiting")
      # @q can not be empty depending on @flush_proc
      @flush_proc.call(self)
      @site_stat.reset('isu') if @q.empty?
      self
    end

    private
    #batch is command array (ary of ary)
    def sort(p,batch)
      verbose("SUB:Recieve [#{batch}] with priority[#{p}]")
      (@outbuf[p]||=[]).concat(batch)
      i=-1
      @outbuf.map{|o|
        verbose("SUB:Outbuf(#{i+=1}) is [#{o}]\n")
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
      @site_stat.reset('isu')
      @outbuf=[[],[],[]]
      @q.clear
      @tid && @tid.run
    end
  end
end
