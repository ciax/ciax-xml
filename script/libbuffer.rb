#!/usr/bin/env ruby
require 'libprompt'
require 'libthreadx'
require 'libappcmd'

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
  # App layer
  module App
    # Command Buffering
    class Buffer < Upd
      include Msg
      attr_accessor :conv_proc
      # sv_stat: Server Status
      def initialize(sv_stat, cobj = nil)
        super()
        @sv_stat = type?(sv_stat, Prompt).init_array(:queue).init_flg(busy: '*')
        # Frm Command Object
        @cobj = cobj
        # Update App Status
        @conv_proc = proc {}
        @outbuf = Outbuf.new
        @id = @sv_stat.get(:id)
        @que = Arrayx.new # For testing
        @cmt_procs.prepend(self, :flush) { ___sv_dw }
      end

      # Take App command entity
      #  -> send frm command batch
      def send(ent, pri = 1)
        __clear if pri.to_i.zero? # interrupt
        cid = type?(ent, CmdBase::Entity).id
        verbose { _exe_text('Executing', cid, 'send que', pri) }
        # batch is frm batch (ary of ary)
        @que.push([pri, ent[:batch], cid])
        self
      end

      # Recv frm command batch
      def recv(que = @que)
        par = que.shift
        verbose { format('Recv from Queue %s:timing', par.inspect) }
        ___pri_sort(*par)
        ___exec_buf if que.empty?
        self
      end

      def server
        # element of que is args of Frm::Cmd
        @que = Threadx::QueLoop.new('Buffer', 'app', @id) do |que|
          verbose { 'Waiting' }
          recv(que)
        end.que
        self
      end

      def alert(str = nil)
        __clear
        str = $ERROR_INFO.to_s + str.to_s
        super(str)
      end

      private

      def ___pri_sort(pri, batch, cid)
        ___sv_up
        @sv_stat.push(:queue, cid)
        batch.each do |args|
          fcmd = { args: args, cid: cid }
          fcmd[:type] = @cobj.set_cmd(args).get(:type) if @cobj
          @outbuf[pri] << fcmd
        end
        verbose { "OutBuf:Recieved:timing #{cid}(#{@id})\n#{@outbuf}" }
      end

      # Execute recieved command
      def ___exec_buf
        until (args = ___reorder_cmd).empty?
          @conv_proc.call(args, 'buffer')
        end
        cmt
      rescue CommError
        alert
      rescue
        alert($ERROR_POSITION)
      end

      # Remove duplicated args and unshift one
      def ___reorder_cmd
        @outbuf.inject([]) { |a, e| ___get_args(a, e) }
      end

      def ___get_args(args, batch)
        if args.empty?
          h = batch.shift
          args.replace h[:args] if h
        end
        ___rm_dup(args, batch)
        args
      end

      def ___rm_dup(args, batch)
        batch.delete_if do |e|
          if e[:type] == 'stat' && e[:args] == args
            warning(format('duplicated stat cmd %s(%s)', args.inspect, e[:cid]))
          end
        end
      end

      def ___sv_up
        verbose { "Busy Up(#{@id}):timing" }
        @sv_stat.up(:busy)
      end

      def ___sv_dw
        verbose { "Busy Down(#{@id}):timing" }
        @sv_stat.flush(:queue, @outbuf.cids).dw(:busy)
      end

      def __clear
        verbose { 'Clear Buffer' }
        @outbuf.clear
        @que.clear
        cmt
      end

      # Multi-level command buffer
      # Structure of @outbuf (4 priority level)
      # [0] Array of interrupt Batch
      # [1] Array of user issued Batch
      # [2] Array of event driven Batch
      # [3] Array of regular update Batch
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
          map.with_index { |o, i| "SUB:Outbuf[#{i}]: #{o.inspect}" }.join("\n")
        end

        def cids
          flatten.map { |h| h[:cid] }.uniq
        end
      end
    end

    if __FILE__ == $PROGRAM_NAME
      ConfOpts.new('[id] [cmd] (par)') do |cfg|
        id = cfg.args.shift
        dbi = Db.new.get(id)
        # dbi.pick already includes :layer, :command, :version
        cobj = Index.new(cfg, dbi.pick)
        cobj.add_rem.add_ext
        buf = Buffer.new(Prompt.new('test', id))
        buf.conv_proc = proc { |par| puts par.inspect }
        buf.send(cobj.set_cmd(cfg.args)).recv
      end
    end
  end
end
