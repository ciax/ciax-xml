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
      def initialize(proj = nil, arc = RecArc.new, par = CmdBase::Parameter.new)
        super()
        self[:id] = proj || ENV['PROJ']
        @current_idx = 0
        self[:dic] = @cache = Hashx.new
        @rec_view = RecView.new(type?(arc, RecArc)) { |id| get(id) }
        propagation(@rec_view)
        # When new macro is generated
        @par = type?(par, CmdBase::Parameter)
      end

      def get(id)
        type?(id, String)
        @cache[id].upd
      end

      def sel(num = nil)
        @current_idx = limit(0, @rec_view.list.size, num.to_i)
        __set_def(current_id)
        self
      end

      def sel_new
        rvl = @rec_view.list
        @current_idx = rvl.size
        __set_def(rvl.last)
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

      def current_id
        @rec_view.list[@current_idx - 1]
      end

      def current_rec
        return if @current_idx.zero?
        get(current_id)
      end

      def default_id
        return unless key?(:default)
        return self[:default] if @par.list.include?(self[:default])
        delete(:default)
        nil
      end

      def to_s
        rec = current_rec
        rec ? rec.to_s : super
      end

      def to_v
        (['<<< ' + colorize("Active Macros [#{self[:id]}]", 2) + ' >>>'] +
        @rec_view.lines(default_id)).join("\n")
      end

      ##### For server ####
      #### Extensions Methods ####
      def ext_remote(host)
        @host = host
        @cache.default_proc = proc do |hash, key|
          hash[key] = Record.new(key).ext_remote(@host)
        end
        @cmt_procs << proc { sel_new }
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
          sel_new
        end
        self
      end

      private

      def __set_def(id)
        return if id.to_i.zero?
        if @par.list.include?(id)
          self[:default] = @par.def_par(id)
        else
          default_id
        end
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
