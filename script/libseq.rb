#!/usr/bin/ruby
require 'libseqfunc'

module CIAX
  # Macro Layer
  module Mcr
    # Sequencer
    class Sequencer
      include Msg
      include SeqFunc
      attr_reader :cfg, :record, :qry, :id, :title, :sv_stat
      # &submcr_proc for executing asynchronous submacro,
      #    which must returns hash with ['id']
      # ent should have [:sequence]'[:dev_list]
      def initialize(ment, pid = '0', valid_keys = [], &submcr_proc)
        @cfg = ment
        type?(@cfg[:dev_list], CIAX::Wat::List)
        _init_record(pid)
        @sv_stat = @cfg[:sv_stat]
        @submcr_proc = submcr_proc
        @depth = 0
        # For Thread mode
        @qry = Query.new(@record, @sv_stat, valid_keys)
      end

      def upd
        @cfg[:sites].each { |site| @cfg[:dev_list].get(site) }
        self
      end

      # For prompt '(stat) [option]'
      def to_v
        @qry.to_v
      end

      def reply(str)
        @qry.reply(str)
      end

      def macro
        Thread.current[:obj] = self
        _show(@record.start)
        sub_macro(@cfg[:sequence], @record)
      rescue Interrupt
        _exec_interrupt
      rescue Verification
        false
      ensure
        _show(@record.finish + "\n")
      end

      def fork
        Threadx.new("Macro(#{@id})", 10) { upd.macro }
      end

      private

      # macro returns result (true=complete /false=error)
      def sub_macro(seqary, mstat)
        _pre_seq(seqary, mstat)
        seqary.each { |e| break(true) unless do_step(e, mstat) }
      rescue Interlock
        false
      rescue Interrupt
        mstat[:result] = 'interrupted'
        raise Interrupt
      ensure
        _post_seq(mstat)
      end

      # Return false if sequence is broken
      def do_step(e, mstat)
        step = @record.add_step(e, @depth)
        begin
          _show step.title
          return true if method('_' + e[:type]).call(e, step, mstat)
        rescue Retry
          retry
        end
      end

      def _pre_seq(seqary, mstat)
        @depth += 1
        @record[:status] = 'run'
        @record[:total_steps] += type?(seqary, Array).size
        mstat[:result] = 'busy'
      end

      def _post_seq(mstat)
        mstat[:result] = 'complete' if mstat[:result] == 'busy'
        @depth -= 1
      end

      def _exec_interrupt
        runary = @sv_stat.get(:run)
        msg("\nInterrupt Issued to running devices #{runary}", 3)
        runary.each do|site|
          @cfg[:dev_list].get(site).exe(['interrupt'], 'user')
        end
      end

      # Initialization Part
      def _init_record(pid)
        @record = Record.new.ext_file.auto_save.mklink # Make latest link
        @record.ext_rsp(@cfg)
        @record[:pid] = pid
        @id = @record[:id]
        @title = @record.title
      end

      # Print section
      def _show(str = nil)
        return unless Msg.fg?
        if defined? yield
          puts indent(@depth) + yield.to_s
        else
          print str
        end
      end
    end

    # Prompt for Mcr
    class Prompt < Prompt
      def initialize(id, opt = {})
        super('mcr', id)
        add_array(:list)
        add_array(:run)
        add_str(:sid)
        add_flg(nonstop: '(nonstop)')
        up(:nonstop) if opt[:n]
      end
    end

    # Mcr Common Parameters
    # Conf includes:
    # :layer_type, :db, :command, :version, :sites, :dev_list, :sv_stat
    # :host, :port
    class Conf < Config
      def initialize(cfg)
        super(cfg)
        db = Db.new
        dbi = db.get
        update(layer_type: 'mcr', db: db)
        # pick already includes :command, :version
        update(dbi.pick([:sites, :id]))
        _init_net(dbi)
        _init_dev_list(cfg)
      end

      private

      def _init_net(dbi)
        self[:host] = self[:option].host || dbi[:host]
        self[:port] = dbi[:port] || 55_555
      end

      # Take App List
      def _init_dev_list(cfg)
        self[:dev_list] = Wat::List.new(cfg, src: 'macro')
        self[:sv_stat] = Prompt.new(self[:id], self[:option])
      end
    end

    if __FILE__ == $PROGRAM_NAME
      ConfOpts.new('[proj] [cmd] (par)', 'ecnr') do |cfg, args|
        mobj = Index.new(Conf.new(cfg))
        mobj.add_rem.add_ext(Ext)
        ent = mobj.set_cmd(args)
        Sequencer.new(ent).upd.macro
      end
    end
  end
end
