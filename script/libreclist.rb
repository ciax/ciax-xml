#!/usr/bin/ruby
require 'librecarc'
require 'libcmdremote'

module CIAX
  # Macro Layer
  module Mcr
    # Visible Record Database
    # Need RecArc to get Parent CID for SeqList
    # Alives Array => R/O here
    #    Parameter[:list] = Prompt[:list]
    # RecArc(Index) > RecList(Records) > SeqList(IDs)
    # RecList : Client Side (Picked at Client)
    # Alives : Server Side
    #
    # Mode:
    #  Remote: get Rec_arc and Record via Http
    #  Local(ext_local) : get Rec_arc and Record from File
    #  Local(ext_save) : write down Rec_arc
    class RecList < Upd
      attr_reader :current_idx, :rec_arc
      def initialize(rec_arc = nil, proj = nil, int = nil)
        super()
        self[:id] = proj || ENV['PROJ']
        int ||= CmdTree::Remote::Int::Group.new(Config.new)
        ___init_int(int)
        # RecArc : R/O
        @rec_arc = rec_arc ? type?(rec_arc, RecArc) : RecArc.new
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
        @list.replace(self[:alives])
        @current_idx = 0
        self
      end

      def append(id)
        return id if @list.include?(id)
        @list << id
        @current_idx = @list.size
        id
      end

      def current_rec
        return if @current_idx.zero?
        id = @list[@current_idx - 1]
        @par.def_par(id)
        get(id)
      end

      # Change alives list
      def get_arc(num = nil)
        num = num ? [self[:alives].size, num.to_i].max : @list.size + 1
        @list.replace(@rec_arc.last(num))
        self
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
        @upd_procs << proc do
          @rec_arc.upd unless self[:alives].each { |id| append(id) }.empty?
        end
        upd
      end

      # Manipulate memory
      def ext_local
        extend(Local).ext_local
      end

      def ext_view
        extend(ListView)
      end

      private

      def ___init_int(int)
        @par = int.pars.last || CmdBase::Parameter.new
        self[:alives] = @par.list
        @valid_keys = type?(int.valid_keys, Array)
        self[:option] = @valid_keys.dup
      end

      def ___init_vars
        @current_idx = 0
        @list = []
        @cache = {}
        @upd_procs << proc do
          @valid_keys.replace((current_rec || self)[:option] || [])
          self[:list] = @list.map { |id| _item(id) }
          self[:default] = @par[:default]
        end
      end

      def _item(id)
        if self[:alives].include?(id)
          ids = %i(id pid cid status option result total_steps steps)
          item = get(id).pick(ids)
          item[:steps] = item[:steps].size
          item[:def] = true if @par[:default] == id
          item
        else
          Hashx[id: id].update(@rec_arc.get(id))
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
          self[:list].each_with_index do |rec, idx|
            page << ___item_view(rec, idx + 1)
          end
          page.join("\n")
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

      # Local mode
      module Local
        def self.extended(obj)
          Msg.type?(obj, RecList)
        end

        def ext_local
          @rec_arc.ext_local.refresh
          @cache.default_proc = proc do |hash, key|
            hash[key] = Record.new(key).ext_local_file.load
          end
          self
        end

        def push(record) # returns self
          id = record[:id]
          return self unless id.to_i > 0
          append(id)
          @cache[id] = record
          self
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
        puts rl.get_arc(args.shift).upd.sel(args.shift)
      end
    end
  end
end
