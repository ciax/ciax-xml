#!/usr/bin/ruby
require 'librecord'
require 'librecarc'
require 'libmcrpar'

module CIAX
  # Macro Layer
  module Mcr
    # Visible Record Database
    # Need RecArc to get Parent CID for SeqList
    # Alives Array is Prompt[:list] = SeqList(alive macro) => R/O here
    # RecArc(Index) > RecList(Records) > SeqList(IDs)
    # RecList : Client Side (Picked at Client)
    # Alives : Server Side (Parameter#list)
    #
    # Mode:
    #  Remote: get Rec_arc and Record via Http
    #  Local(ext_local) : get Rec_arc and Record from File
    #  Local(ext_save) : write down Rec_arc
    class RecList < Upd
      attr_reader :par, :valid_keys
      def initialize(proj = ENV['PROJ'], alives = [], valid_keys = [])
        super()
        @proj = proj
        @alives = type?(alives, Array)
        @valid_keys = type?(valid_keys, Array)
        self[:option] = @valid_keys.dup
        @par = Parameter.new
        @rec_arc = RecArc.new
        @cache = {}
        ___init_procs
      end

      def get(id)
        type?(id, String)
        @cache[id].upd
      end

      def sel(num)
        @par.sel(num)
        cmt
      end

      def flush
        @par.flush(@alives)
        cmt
      end

      def current_rec
        num = @par.current_idx
        return if num.zero?
        get(@par.current_rid)
      end

      # Change alives list
      def get_arc(num = 1)
        upd
        rkeys = @rec_arc.list.keys
        @par.list.replace(rkeys.sort.uniq.last(num.to_i))
        self
      end

      def add_arc
        get_arc(@par.list.size + 1)
        @par.sel_last
        cmt
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
        self
      end

      # Manipulate memory
      def ext_local
        extend(Local).ext_local
        self
      end

      def refresh_arc_bg # returns Thread
        Threadx::Fork.new('RecArc(rec_list)', 'mcr', @id) do
          @rec_arc.clear.refresh
        end
      end

      private

      def ___list_view
        page = ['<<< ' + colorize("Active Macros [#{@proj}]", 2) + ' >>>']
        @par.list.each_with_index do |id, idx|
          page << ___item_view(id, idx + 1)
        end
        page.join("\n")
      end

      def ___item_view(id, idx)
        rec = @alives.include?(id) ? get(id) : @rec_arc.get(id)
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

      def ___init_procs
        @cmt_procs << proc do
          # If current_rec is alive
          @valid_keys.replace((current_rec || self)[:option] || [])
        end
        @upd_procs << proc do
          next if (@alives - @par.list).empty?
          @rec_arc.upd
          @par.sel_last
          cmt
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
          @par.push(id)
          @cache[id] = record
          @rec_arc.push(record)
          cmt
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
