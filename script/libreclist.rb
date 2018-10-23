#!/usr/bin/ruby
require 'librecord'
require 'librecarc'

module CIAX
  # Macro Layer
  module Mcr
    # Visible Record Database
    # Need RecArc to get Parent CID for SeqList
    # Alives Array is Parameter[:list] = SeqList(alive macro)
    # RecArc(Index) > RecList(Records) > SeqList(IDs)
    # RecList : Client Side (Picked at Client)
    # Alives : Server Side (Parameter#list)
    #
    # Mode:
    #  Remote: get Rec_arc and Record via Http
    #  Local(ext_local) : get Rec_arc and Record from File
    #  Local(ext_save) : write down Rec_arc
    class RecList < Hashx
      attr_reader :rec_arc
      def initialize(proj = ENV['PROJ'], alives = [])
        super()
        @proj = proj
        @rec_arc = RecArc.new
        @alives = type?(alives, Array)
      end

      # delete from @records other than in ary
      def flush(ary)
        (keys - ary).each do |id|
          delete(id)
        end
        cmt
      end

      def push(record) # returns self
        id = record[:id]
        return self unless id.to_i > 0
        self[id] = record
        yield record if defined? yield
        cmt
      end

      def get(id)
        type?(id, String)
        super
      end

      def ordinal(num)
        return self if (num.to_i * size).zero?
        num = limit(1, size, num.to_i)
        get(keys.sort[num - 1])
      end

      # Change alives list
      def get_arc(num = 1)
        rkeys = @rec_arc.upd.list.keys + @alives
        picked = rkeys.sort.uniq.last(num.to_i)
        picked.each { |id| get(id) }
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
        self.default_proc = proc do |hash, key|
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
        keys.each_with_index do |id, idx|
          page << ___item_view(id, idx + 1)
        end
        page.join("\n")
      end

      def ___item_view(id, idx)
        rec = get(id)
        tim = Time.at(id[0..9].to_i).to_s
        title = "[#{idx}] #{id} (#{tim}) by #{___get_pcid(rec[:pid])}"
        msg = "#{rec[:cid]} #{rec.step_num}"
        msg << ___result_view(rec)
        itemize(title, msg)
      end

      def ___result_view(rec)
        if rec[:status] == 'end'
          "(#{rec[:result]})"
        else
          msg = "(#{rec[:status]})"
          msg << optlist(rec[:option]) if rec.last
          msg
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
          self.default_proc = proc do |hash, key|
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
        puts rl.get_arc(args.shift).ordinal(args.shift)
      end
    end
  end
end
