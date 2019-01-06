#!/usr/bin/ruby
require 'librecview'
require 'libcmdremote'

module CIAX
  # Macro Layer
  module Mcr
    # Visible Record Dictionary
    # Need RecArc to get Parent CID
    # Contents
    #   @cache: Dic of Record
    # Alives Array => R/O here
    #   Parameter[:list] = Prompt[:list](@par.list)
    # RecView(Index) > RecDic(Records)
    # RecDic : Client Side (Picked at Client)
    # Alives : Server Side
    #
    # Mode:
    #  Remote: get RecArc and Record via Http
    #  Local(ext_local) : get RecArc and Record from File
    #  Local(ext_save) : write down RecArc
    class RecDic < Upd
      attr_reader :current_idx, :rec_view
      def initialize(rec_arc = RecArc.new, proj = nil, int = nil)
        super()
        self[:id] = proj || ENV['PROJ']
        ___init_int(int)
        @current_idx = 0
        self[:dic] = @cache = Hashx.new
        @rec_view = RecView.new(rec_arc) { |id| get(id) }
        ___init_upd_proc
      end

      def get(id)
        type?(id, String)
        @cache[id].upd
      end

      def sel(num = nil)
        rvl = @rec_view.list
        cdx = @current_idx = limit(0, rvl.size, (num || rvl.size).to_i)
        self[:default] = @par.def_par(rvl[cdx - 1]) if cdx > 0
        self
      end

      def inc(num = 1)
        @rec_view.inc(num.to_i)
        self
      end

      def flush
        @rec_view.clear.inc(@par.list.size)
        @current_idx = 0
        self
      end

      def current_rec
        return if @current_idx.zero?
        get(self[:default])
      end

      def to_s
        rec = current_rec
        rec ? rec.to_s : super
      end

      def to_v
        (['<<< ' + colorize("Active Macros [#{self[:id]}]", 2) + ' >>>'] +
        @rec_view.lines(self[:default])).join("\n")
      end

      ##### For server ####
      #### Extensions Methods ####
      def ext_remote(host)
        @host = host
        @cache.default_proc = proc do |hash, key|
          hash[key] = Record.new(key).ext_remote(@host)
        end
        self
      end

      # Manipulate memory
      def ext_local
        # Get Archive Record
        @cache.default_proc = proc do |hash, key|
          hash[key] = Record.new(key).ext_local_file.ext_load
        end
        # Get Live Record
        @rec_view.rec_arc.ext_local.ext_load.push_procs << proc do |rec|
          @cache[rec[:id]] = rec
        end
        self
      end

      private

      def ___init_int(int)
        int ||= CmdTree::Remote::Int::Group.new(Config.new)
        @par = int.pars.last || CmdBase::Parameter.new
      end

      def ___init_upd_proc
        upd_propagate(@rec_view)
        cmt_propagate(@rec_view)
        # When new macro is generated
        @cmt_procs << proc { sel }
      end
    end

    if __FILE__ == $PROGRAM_NAME
      GetOpts.new('[num]', options: 'chr') do |opts, args|
        Msg.args_err if args.empty?
        rl = RecDic.new
        if opts.cl?
          rl.ext_remote(opts.host)
        else
          rl.ext_local
        end
        puts rl.inc(args.shift).sel(args.shift)
      end
    end
  end
end
