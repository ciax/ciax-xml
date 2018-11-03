#!/usr/bin/ruby
require 'librecord'
require 'librecarc'

module CIAX
  # Macro Layer
  module Mcr
    # Visible Record Database
    # Need RecArc to get Parent CID for SeqList
    # Alives Array => R/O here
    #    Parameter[:list] = Prompt[:list] = SeqList(alive macro)
    # RecArc(Index) > RecList(Records) > SeqList(IDs)
    # RecList : Client Side (Picked at Client)
    # Alives : Server Side
    #
    # Mode:
    #  Remote: get Rec_arc and Record via Http
    #  Local(ext_local) : get Rec_arc and Record from File
    #  Local(ext_save) : write down Rec_arc
    class RecList < Upd
      attr_reader :current_idx
      def initialize(proj = ENV['PROJ'], par = Parameter.new, valid_keys = [])
        super()
        @proj = proj
        @par = type?(par, CmdBase::Parameter)
        @valid_keys = type?(valid_keys, Array)
        self[:option] = @valid_keys.dup
        @rec_arc = RecArc.new
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

      def append(id)
        return id if @list.include?(id)
        @list << id
        @current_idx = @list.size
        id
      end

      def current_rec
        return if @current_idx.zero?
        id = @list[@current_idx - 1]
        @par.set_def(id)
        get(id)
      end

      # Change alives list
      def get_arc(num = nil)
        num = num ? [@par.list.size, num.to_i].max : @list.size + 1
        rkeys = @rec_arc.upd.list.keys.sort.uniq
        @list.replace(rkeys.last(num))
        self
      end

      # Show Index of Alives Item
      def to_v
        ___list_view
      end

      def to_s
        rec = current_rec
        rec ? rec.to_s : to_v
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
          @rec_arc.upd unless @par.list.each { |id| append(id) }.empty?
        end
        self
      end

      # Manipulate memory
      def ext_local
        extend(Local).ext_local
        self
      end

      private

      def ___list_view
        page = ['<<< ' + colorize("Active Macros [#{@proj}]", 2) + ' >>>']
        @list.each_with_index do |id, idx|
          page << ___item_view(id, idx + 1)
        end
        page.join("\n")
      end

      def ___item_view(id, idx)
        rec = @par.list.include?(id) ? get(id) : @rec_arc.get(id)
        tim = Time.at(id[0..9].to_i).to_s
        title = "[#{idx}] #{id} (#{tim}) by #{___get_pcid(rec[:pid])}"
        itemize(title, (rec[:cid]).to_s + ___result_view(rec))
      end

      def ___result_view(rec)
        if rec.is_a?(Record) && rec[:status] != 'end'
          msg = " #{rec.step_num}(#{rec[:status]})"
          msg << optlist(rec[:option]) if rec.last
          msg
        else
          " (#{rec[:result]})"
        end
      end

      def ___get_pcid(pid)
        return 'user' if pid == '0'
        @rec_arc.list[pid][:cid]
      end

      def ___init_vars
        @current_idx = 0
        @list = []
        @cache = {}
        @upd_procs << proc do
          @valid_keys.replace((current_rec || self)[:option] || [])
        end
      end

      # Local mode
      module Local
        def self.extended(obj)
          Msg.type?(obj, RecList)
        end

        def push(record) # returns self
          id = record[:id]
          return self unless id.to_i > 0
          @par.list << append(id)
          @cache[id] = record
          @rec_arc.push(record)
          self
        end

        def refresh_arc_bg # returns Thread
          Threadx::Fork.new('RecArc(rec_list)', 'mcr', @id) do
            @rec_arc.clear.refresh
          end
        end

        def ext_local
          @rec_arc.ext_local.refresh
          @cache.default_proc = proc do |hash, key|
            hash[key] = Record.new(key).ext_local_file.load
          end
          self
        end

        def ext_save
          @rec_arc.ext_save
          self
        end
      end
    end

    if __FILE__ == $PROGRAM_NAME
      GetOpts.new('[num]', options: 'chs') do |opts, args|
        Msg.args_err if args.empty?
        rl = RecList.new
        if opts.cl?
          rl.ext_remote(opts.host)
        else
          rl.ext_local
          rl.ext_save.refresh_arc_bg.join if opts.sv?
        end
        puts rl.get_arc(args.shift).sel(args.shift)
      end
    end
  end
end
