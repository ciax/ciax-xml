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
  # Command Buffering
  class Buffer
    include Msg
    NS_COLOR = 11
    attr_accessor :flush_proc, :recv_proc
    # sv_stat: Server Status
    def initialize(sv_stat)
      @sv_stat = type?(sv_stat, Prompt)
      @sv_stat.put(:busy, [])
      # element of @q is bunch of frm args corresponding an appcmd
      @q = Queue.new
      @tid = nil
      @flush_proc = proc {}
      @recv_proc = proc {}
      clear
    end

    # Send app entity
    def send(ent, n = 1)
      clear if n == 0 # interrupt
      cid = type?(ent, Entity).id
      # batch is frm batch (ary of ary)
      batch = ent[:batch]
      return self if batch.empty?
      sv_up(cid)
      @q.push(pri: n, batch: batch, cid: cid)
      self
    end

    def server
      @tid = ThreadLoop.new('Buffer', 12) do
        exec_buf if @q.empty?
        verbose { 'Waiting' }
        pri_sort(@q.shift)
      end
      self
    end

    def alive?
      @tid && @tid.alive?
    end

    private

    # Structure of @outbuf (4 level arrays)
    # [0] Array of interrupt Batch
    # [1] Array of user issued Batch
    # [2] Array of event driven Batch
    # [3] Array of redular update Batch
    #  Batch: [ Property, ..]
    #  Property: [ Args, cid ]
    #  Args: ['cmd','par','par'..]

    def pri_sort(rcv)
      verbose { "Recieved #{rcv}" }
      buf = (@outbuf[rcv[:pri]] ||= [])
      buf.concat rcv[:batch].map { |args| [args, rcv[:cid]] }
      verbose do
        @outbuf.map.with_index { |o, i| "SUB:Outbuf(#{i}) is [#{o}]\n" }
      end
    end

    # Execute recieved command
    def exec_buf
      while (args = _reorder_cmd_)
        @recv_proc.call(args, 'buffer')
      end
    rescue
      clear
      alert($ERROR_INFO.to_s)
    ensure
      sv_dw
    end

    # Remove duplicated args and unshift one
    def _reorder_cmd_
      args = nil
      cids = []
      @outbuf.each { |ary| args = _get_args_(args, ary, cids) }
      cids.uniq!
      flush if cids.size < @sv_stat[:busy].size
      @sv_stat[:busy].replace(cids)
      args
    end

    def _get_args_(args, ary, cids)
      if args
        ary.delete_if do |p|
          warning("remove duplicated cmd #{args.inspect}") if p[0] == args
        end
      else
        args, cid = ary.shift
        cids << cid if cid
      end
      args
    end

    def sv_up(cid)
      @sv_stat[:busy] << cid
      @sv_stat.set(:isu)
    end

    def sv_dw
      @sv_stat.reset(:isu)
      @sv_stat[:busy].clear
    end

    def clear
      @outbuf = [[], [], []]
      @q.clear
      @tid && @tid.run
      flush
    end

    def flush
      @flush_proc.call(self)
      self
    end
  end
end
