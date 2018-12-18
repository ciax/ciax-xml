#!/usr/bin/ruby
require 'librecview'
require 'libcmdremote'

module CIAX
  # Macro Layer
  module Mcr
    # Visible Record Database
    # Need RecArc to get Parent CID for SeqList
    # Contents
    #   @list: Array of macro ID
    #   self[:list] : Array of macro Title
    # Alives Array => R/O here
    #   Parameter[:list] = Prompt[:list]
    # RecArc(Index) > RecList(Records) > SeqList(IDs)
    # RecList : Client Side (Picked at Client)
    # Alives : Server Side
    #
    # Mode:
    #  Remote: get Rec_arc and Record via Http
    #  Local(ext_local) : get Rec_arc and Record from File
    #  Local(ext_save) : write down Rec_arc
    class RecList < Upd
      attr_reader :current_idx, :rec_view
      def initialize(rec_view = nil, proj = nil, int = nil)
        super()
        self[:id] = proj || ENV['PROJ']
        int ||= CmdTree::Remote::Int::Group.new(Config.new)
        ___init_int(int)
        # RecArc : R/O
        @rec_view = rec_view || RecView.new(RecArc.new)
        @rec_arc = type?(@rec_view, RecView).rec_arc
        ___init_vars
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

      def set_max(num)
        @rec_view.max = [num.to_i, @par.list.size].max
        @list.replace(@rec_view.list)
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

      ##### For server ####
      #### Extensions Methods ####
      def ext_remote(host)
        @host = host
        @rec_arc.ext_remote(host)
        @cache.default_proc = proc do |hash, key|
          hash[key] = Record.new(key).ext_remote(@host)
        end
        self
      end

      # Manipulate memory
      def ext_local(mcr_list = nil)
        @rec_arc.ext_local.refresh
        # Get Live Record
        @rec_arc.cmt_procs << proc { @cache.update(mcr_list.records) } if mcr_list
        # Get Archive Record
        @cache.default_proc = proc do |hash, key|
          hash[key] = Record.new(key).ext_local_file.auto_load
        end
      end

      def ext_view
        extend(ListView)
      end

      private

      def ___init_int(int)
        @par = int.pars.last || CmdBase::Parameter.new
        @valid_keys = type?(int.valid_keys, Array)
        self[:option] = @valid_keys.dup
      end

      def ___init_vars
        @current_idx = 0
        @list = []
        @cache = {}
        @upd_procs << proc do
          @rec_arc.upd
          @valid_keys.replace((current_rec || self)[:option] || [])
          self[:default] = @par[:default]
        end
      end

      # Divided for Rubocop
      module ListView
        def self.extended(obj)
          Msg.type?(obj, RecList)
        end

        # Show Index of Alives Item
        def to_v
          ___list_view
        end

        private

        def ___list_view
          page = ['<<< ' + colorize("Active Macros [#{self[:id]}]", 2) + ' >>>']
          @par.list.each_with_index do |id, idx|
            page << ___item_view(@cache[id], idx + 1)
          end
          (page + @rec_view.lines).join("\n")
        end

        def ___item_view(rec, idx)
          id = rec[:id]
          tim = ___get_time(id)
          pcid = ___get_pcid(rec[:pid])
          title = rec[:def] ? '*' : ' '
          title << format('[%s] %s (%s) by %s', idx, id, tim, pcid)
          itemize(title, rec[:cid].to_s + ___result_view(rec))
        end

        def ___result_view(rec)
          if rec.key?(:status) && rec[:status] != 'end'
            args = rec.pick(%i(steps total_steps status)).values
            msg = format(' [%s/%s](%s)', *args)
            msg << optlist(rec[:option])
            msg
          else
            " (#{rec[:result]})"
          end
        end

        def ___get_time(id)
          Time.at(id[0..9].to_i).to_s
        end

        def ___get_pcid(pid)
          return 'user' if pid == '0'
          @rec_arc.get(pid)[:cid]
        end
      end
    end

    if __FILE__ == $PROGRAM_NAME
      GetOpts.new('[num]', options: 'chr') do |opts, args|
        Msg.args_err if args.empty?
        rl = RecList.new.ext_view
        if opts.cl?
          rl.ext_remote(opts.host)
        else
          rl.ext_local
        end
        puts rl.set_max(args.shift).upd.sel(args.shift)
      end
    end
  end
end
