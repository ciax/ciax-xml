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
      attr_reader :list, :par
      def initialize(proj = ENV['PROJ'], alives = [])
        super()
        @proj = proj
        @par = Parameter.new
        @list = @par.list
        @alives = type?(alives, Array)
        @rec_arc = RecArc.new
        @cache = {}
      end

      # For server
      def push(record) # returns self
        id = record[:id]
        return self unless id.to_i > 0
        @list << id
        @cache[id] = record
        yield record if defined? yield
        cmt
      end

      def get(id)
        type?(id, String)
        @cache[id].upd
      end

      def sel(num)
        @par.sel(num)
        self
      end

      def current_rec
        num = @par.current_idx
        return if (num * @list.size).zero?
        get(@list[limit(1, @list.size, num) - 1])
      end

      # Change alives list
      def get_arc(num = 1)
        rkeys = @rec_arc.list.keys + @alives
        @list.replace(rkeys.sort.uniq.last(num.to_i))
        self
      end

      # Show Index of Alives Item
      def to_v
        ___list_view
      end

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
        @list.each_with_index do |id, idx|
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

        def ext_save
          @rec_arc.ext_save
          self
        end

        def push(record) # returns self
          super { |r| @rec_arc.push(r) }
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
        rl.get_arc(args.shift).sel(args.shift)
        puts rl.current_rec || rl
      end
    end
  end
end
