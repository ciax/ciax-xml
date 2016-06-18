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
      # Update App Status
      @flush_proc = proc {}
      @recv_proc = proc {}
      @outbuf = Outbuf.new
      @id = @sv_stat.get(:id)
    end

    # Send app entity
    def send(ent, n = 1)
      clear if n == 0 # interrupt
      cid = type?(ent, Cmd::Entity).id
      verbose { "Execute #{cid}(#{@id}):timing" }
      # batch is frm batch (ary of ary)
      batch = ent[:batch]
      @que_buf.push(pri: n, batch: batch, cid: cid) unless batch.empty?
      self
    end

    def server
      # element of que is args of Frm::Cmd
      @que_buf = Threadx::QueLoop.new('Buffer', 'app', @id) do |iq, oq|
        verbose { 'Waiting' }
        pri_sort(iq.shift)
        sv_up
        oq.push(true)
        exec_buf('app') if iq.empty?
      end
      self
    end

    def alive?
      @que_buf && @que_buf.alive?
    end

    def wait_busy_up
      @que_buf.shift
    end

    private

    def pri_sort(rcv)
      pri = rcv[:pri]
      cid = rcv[:cid]
      @sv_stat.push(:queue, cid)
      rcv[:batch].each do |args|
        @outbuf[pri] << { args: args, cid: cid }
      end
      verbose { "OutBuf:Recieved:timing #{cid}(#{@id})\n#{@outbuf}" }
    end

    # Execute recieved command
    def exec_buf(src)
      until (args = _reorder_cmd_).empty?
        @recv_proc.call(args, src)
      end
      flush
    rescue CommError
      alert
    rescue
      alert($ERROR_POSITION)
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
        if e[:args] == args
          warning("duplicated cmd #{args.inspect}(#{e[:cid]})")
        end
      end
    end

    def sv_up
      verbose { "Busy Up(#{@id}):timing" }
      @sv_stat.up(:busy)
    end

    def sv_dw
      verbose { "Busy Down(#{@id}):timing" }
      @sv_stat.dw(:busy)
      @sv_stat.flush(:queue, @outbuf.cids)
    end

    def clear
      @outbuf.clear
      @que_buf.clear
      @que_buf && @que_buf.run
      flush
    end

    def flush
      @flush_proc.call(self)
      sv_dw
      verbose do
        var = @sv_stat.pick(%i(busy queue)).inspect
        "Flush buffer(#{@id}):timing#{var}"
      end
      self
    end

    def alert(str = nil)
      clear
      str = $ERROR_INFO.to_s + str.to_s
      super(str)
    end

    # Multi-level command buffer
    # Structure of @outbuf (4 level arrays)
    # [0] Array of interrupt Batch
    # [1] Array of user issued Batch
    # [2] Array of event driven Batch
    # [3] Array of redular update Batch
    #  Batch: [ Property, ..]
    #  Property: { args:, cid: }
    #  args: ['cmd','par','par'..]
    class Outbuf < Array
      def initialize
        super(4) { [] }
      end

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
