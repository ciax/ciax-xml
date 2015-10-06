#!/usr/bin/ruby
require 'libprompt'
require 'libthreadx'
require 'libgroup'

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
    NS_COLOR = 11
    # sv_stat: Server Status
    def initialize(id, ver, sv_stat = {})
      super('issue', id, ver)
      update('pri' => '', 'cid' => '')
      @sv_stat = type?(sv_stat, Prompt)
      # element of @q is bunch of frm args corresponding an appcmd
      @q = Queue.new
      @tid = nil
      @flush_proc = proc {}
      @recv_proc = proc {}
      clear
    end

    def recv_proc
      @recv_proc = proc { |args, src| yield args, src }
      self
    end

    # Send frm command batch (ary of ary)
    def send(ent, n = 1)
      type?(ent, Entity)
      clear if n == 0
      batch = ent[:batch]
      # batch is frm batch (ary of ary)
      update('time' => now_msec, 'pri' => n, 'cid' => ent.id)
      unless batch.empty?
        @sv_stat.set('isu')
        @q.push(:pri => n, :batch => batch)
      end
      self
    end

    def server
      @tid = ThreadLoop.new("Buffer(#{self['id']})", 12) do
        begin
          verbose { 'SUB:Waiting' }
          rcv = @q.shift
          sort(rcv[:pri], rcv[:batch])
          while (args = pick)
            @recv_proc.call(args, 'buffer')
          end
          upd
        rescue
          clear
          alert($!.to_s)
        end
      end
      self
    end

    def alive?
      @tid && @tid.alive?
    end

    def upd_core
      # @q can not be empty depending on @flush_proc
      @sv_stat.reset('isu') if @q.empty?
      self
    end

    private
    # batch is command array (ary of ary)
    def sort(p, batch)
      verbose { "SUB:Recieve [#{batch}] with priority[#{p}]" }
      (@outbuf[p] ||= []).concat(batch)
      i = -1
      @outbuf.map do|o|
        verbose { "SUB:Outbuf(#{i += 1}) is [#{o}]\n" }
      end
    end

    # Remove duplicated args and pop one
    def pick
      args = nil
      @outbuf.size.times do|i|
        if args
          @outbuf[i].delete(args)
        else
          args = @outbuf[i].shift
        end
      end
      args
    end

    def clear
      @sv_stat.reset('isu')
      @outbuf = [[], [], []]
      @q.clear
      @tid && @tid.run
    end
  end
end
