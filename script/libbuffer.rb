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
  class Buffer < Varx
    NS_COLOR = 11
    # sv_stat: Server Status
    def initialize(id, ver, sv_stat = Prompt.new)
      super('issue', id, ver)
      update('pri' => '', 'cid' => '')
      @sv_stat = type?(sv_stat, Prompt).add_db('isu' => '*')
      @sv_stat.put('busy', [])
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

    # Send app entity
    def send(ent, n = 1)
      clear if n == 0 # interrupt
      cid = type?(ent, Entity).id
      batch = ent[:batch]
      # batch is frm batch (ary of ary)
      update('time' => now_msec, 'pri' => n, 'cid' => cid)
      unless batch.empty?
        @sv_stat['busy'] << cid
        @sv_stat.set('isu')
        @q.push(pri: n, batch: batch, cid: cid)
      end
      self
    end

    def server
      @tid = ThreadLoop.new("Buffer(#{self['id']})", 12) do
        next if @q.empty? && exec
        verbose { 'SUB:Waiting' }
        pri_sort(@q.shift)
      end
      self
    end

    def alive?
      @tid && @tid.alive?
    end

    # @q can not be empty depending on @flush_proc
    def upd_core
      if @q.empty?
        @sv_stat.reset('isu')
        @sv_stat['busy'].clear
      end
      self
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
      buf = (@outbuf[rcv[:pri]] ||= [])
      buf.concat rcv[:batch].map { |args| [args, rcv[:cid]] }
      verbose do
        @outbuf.map.with_index { |o, i| "SUB:Outbuf(#{i}) is [#{o}]\n" }
      end
    end

    # Execute recieved command
    def exec
      while (args = pick)
        @recv_proc.call(args, 'buffer')
      end
      upd
    rescue
      clear
      alert($ERROR_INFO.to_s)
    end

    # Remove duplicated args and pop one
    def pick
      args = nil
      cids = []
      @outbuf.each { |ary| args = fetch_arg(args, ary, cids) }
      rep = @sv_stat['busy'] & cids
      @sv_stat['busy'].replace(rep)
      args
    end

    def fetch_arg(args, ary, cids)
      if args
        ary.delete_if do |p|
          warning("remove duplicated cmd #{args.inspect}") if p[0] == args
        end
      else
        args, cid = ary.shift
        cids << cid
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
