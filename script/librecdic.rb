#!/usr/bin/env ruby
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
      attr_reader :current_page, :rec_view
      def initialize(arc = RecArc.new, par = CmdBase::Parameter.new)
        super()
        @current_page = 0
        self[:dic] = @cache = Hashx.new
        @rec_view = RecView.new(type?(arc, RecArc)) { |id| get(id) }
        propagation(@rec_view)
        # When new macro is generated
        @par = type?(par, CmdBase::Parameter)
        @last_size = 0
        arc.host ? ___ext_remote : ___ext_local
      end

      def get(id)
        type?(id, String)
        @cache[id].upd
      end

      def sel(num = nil)
        @current_page = limit(num.to_i, 0, @rec_view.list.size)
        __set_def(current_id)
        self
      end

      def sel_new
        rvl = @rec_view.list
        if rvl.size > @last_size
          @current_page = rvl.size
          __set_def(rvl.last)
          @last_size = rvl.size
        end
        self
      end

      def inc(num = 1)
        @rec_view.inc(num.to_i)
        @last_size = @rec_view.list.size
        self
      end

      def flush
        @rec_view.clear.inc(@par.list.size)
        @current_page = 0
        @last_size = @rec_view.list.size
        self
      end

      def current_id
        @rec_view.list[@current_page - 1]
      end

      def current_rec
        @rec_view.chk_def(@par.list)
        return if @current_page.zero?
        get(current_id)
      end

      def to_v
        (current_rec || @rec_view).to_v
      end

      def to_r
        (current_rec || @rec_view).to_r
      end

      private

      ##### For server ####
      #### Extensions Methods ####
      def ___ext_remote
        @host = @rec_view.rec_arc.host
        @cache.default_proc = proc do |hash, key|
          hash[key] = Record.new(key).ext_remote(@host)
        end
        @cmt_procs.append { sel_new }
        self
      end

      # Manipulate memory
      def ___ext_local
        # Get Archive Record
        @cache.default_proc = proc do |hash, key|
          hash[key] = Record.new(key).ext_local.load
        end
        # Get Live Record
        @rec_view.rec_arc.ext_local.load.push_procs << proc do |rec|
          @cache[rec[:id]] = rec
          sel_new
        end
        self
      end

      def __set_def(id)
        return if id.to_i.zero?
        @rec_view.put_def(@par.def_par(id))
      end
    end

    if __FILE__ == $PROGRAM_NAME
      GetOpts.new('[num]', options: 'chr') do |opts, args|
        Msg.args_err if args.empty?
        ra = RecArc.new.mode(opts.host)
        puts RecDic.new(ra).inc(args.shift).sel(args.shift)
      end
    end
  end
end
