#!/usr/bin/ruby
require 'librecview'
require 'libcmdremote'

module CIAX
  # Macro Layer
  module Mcr
    # Visible Record Dictionary
    # Need RecArc to get Parent CID
    # Contents
    #   @list: Array of macro ID
    # Alives Array => R/O here
    #   Parameter[:list] = Prompt[:list](@par.list)
    # RecArc(Index) > RecDic(Records)
    # RecDic : Client Side (Picked at Client)
    # Alives : Server Side
    #
    # Mode:
    #  Remote: get RecArc and Record via Http
    #  Local(ext_local) : get RecArc and Record from File
    #  Local(ext_save) : write down RecArc
    class RecDic < Upd
      attr_reader :current_idx, :rec_view
      def initialize(rec_arc = nil, proj = nil, int = nil)
        super()
        self[:id] = proj || ENV['PROJ']
        int ||= CmdTree::Remote::Int::Group.new(Config.new)
        ___init_int(int)
        @current_idx = 0
        @cache = {}
        # RecArc : R/O
        @rec_arc = rec_arc || RecArc.new
        @rec_view = RecView.new(@rec_arc, @cache)
        @list = @rec_view.list
        ___init_upd_proc
      end

      def get(id)
        type?(id, String)
        @cache[id].upd
      end

      def sel(num)
        @current_idx = limit(0, @list.size, num.to_i)
        self
      end

      def flush
        @list.replace(@par.list)
        @current_idx = 0
        self
      end

      def current_rec
        return if @current_idx.zero?
        id = @list[@current_idx - 1]
        @par.def_par(id)
        get(id)
      end

      def to_s
        rec = current_rec
        rec ? rec.to_s : super
      end

      def to_v
        (['<<< ' + colorize("Active Macros [#{self[:id]}]", 2) + ' >>>'] +
        @rec_view.lines).join("\n")
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
      def ext_local(mcr_dic = nil)
        @rec_arc.ext_local.refresh
        # Get Live Record
        @rec_arc.cmt_procs << proc { @cache.update(mcr_dic.records) } if mcr_dic
        # Get Archive Record
        @cache.default_proc = proc do |hash, key|
          hash[key] = Record.new(key).ext_local_file.auto_load.upd
        end
      end

      private

      def ___init_int(int)
        @par = int.pars.last || CmdBase::Parameter.new
        @valid_keys = type?(int.valid_keys, Array)
        self[:option] = @valid_keys.dup
      end

      def ___init_upd_proc
        upd_propagate(@rec_arc)
        @upd_procs << proc do
          ___detect_inc
          @valid_keys.replace((current_rec || self)[:option] || [])
          self[:default] = @par[:default]
        end
      end

      def ___detect_inc
        newids = (@par.list - @list)
        return if newids.empty?
        @list.concat(newids)
        sel(@list.size)
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
        rl.rec_view.tail(args.shift)
        puts rl.upd.sel(args.shift)
      end
    end
  end
end
