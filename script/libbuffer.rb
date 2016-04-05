#!/usr/bin/ruby
require 'libprompt'
require 'libthreadx'
require 'libcmdgroup'

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
    attr_accessor :flush_proc, :recv_proc
    # sv_stat: Server Status
    def initialize(sv_stat)
      @sv_stat = type?(sv_stat, Prompt)
      @sv_stat.add_array(:queue)
      # element of @q is bunch of frm args corresponding an appcmd
      @q = Queue.new
      @tid = nil
      @flush_proc = proc {}
      @recv_proc = proc {}
      @outbuf = Outbuf.new
      @id = @sv_stat.get(:id)
      clear
    end

    # Send app entity
    def send(ent, n = 1)
      clear if n == 0 # interrupt
      cid = type?(ent, Cmd::Entity).id
      verbose { "Execute #{cid}(#{@id}):timing" }
      # batch is frm batch (ary of ary)
      batch = ent[:batch]
      return self if batch.empty?
      sv_up(cid)
      @q.push(pri: n, batch: batch, cid: cid)
      self
    end

    def server
      @tid = ThreadLoop.new("Buffer(#{@id})", 12) do
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
    #  Property: { args:, cid: }
    #  args: ['cmd','par','par'..]

    def pri_sort(rcv)
      enclose("OutBuf:Recieved #{rcv[:cid]}(#{@id})", 'End') do
        buf = @outbuf[rcv[:pri]]
        buf.concat rcv[:batch].map { |args| { args: args, cid: rcv[:cid] } }
        verbose { @outbuf.to_s }
      end
    end

    # Execute recieved command
    def exec_buf
      until (args = _reorder_cmd_).empty?
        @recv_proc.call(args, 'buffer')
      end
      flush
    rescue CommError
      alert
    rescue
      alert($ERROR_POSITION)
    ensure
      sv_dw
    end

    # Remove duplicated args and unshift one
    def _reorder_cmd_
      args = []
      @outbuf.each { |batch| _get_args_(args, batch) }
      args
    end

    def _get_args_(args, batch)
      if args.empty?
        h = batch.shift || return
        args.replace h[:args]
      end
      batch.delete_if do |e|
        warning("duplicated cmd #{args.inspect}(#{e[:cid]})") if e[:args] == args
      end
    end

    def sv_up(cid)
      verbose { "Busy Up(#{@id}):timing" }
      @sv_stat.up(:busy)
      @sv_stat.push(:queue, cid)
    end

    def sv_dw
      verbose { "Busy Down(#{@id}):timing" }
      @sv_stat.dw(:busy)
      @sv_stat.flush(:queue)
    end

    def clear
      @outbuf.clear
      @q.clear
      @tid && @tid.run
      flush
    end

    def flush
      @sv_stat.flush(:queue, @outbuf.cids)
      @flush_proc.call(self)
      verbose { "Flush buffer(#{@id}):timing#{@sv_stat.pick(%i(busy queue)).to_j}" }
      self
    end

    def alert(str = nil)
      clear
      str = $ERROR_INFO.to_s + str.to_s
      super(str)
    end

    # Multi-level command buffer
    class Outbuf < Array
      def clear
        super
        push [], [], [], []
      end

      def to_s # String Array
        map.with_index { |o, i| "SUB:Outbuf(#{i}) is #{o}" }.join("\n")
      end

      def cids
        flatten.map { |h| h[:cid] }.uniq
      end
    end
  end
end
