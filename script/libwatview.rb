#!/usr/bin/ruby
require 'libwatrsp'

# View is not used for computing, just for apperance for user.
# Some information is added from Dbi
# So the convert process (upd) will be included in to_s
module CIAX
  # Watch Layer
  module Wat
    # Decorate the event data (Put caption,symbole,etc.) from WDB
    class View < Upd
      def initialize(event)
        super()
        @event = type?(event, Event)
        wdb = type?(event.dbi, Dbi)[:watch]
        _init_stat(wdb || { index: [] })
        _init_cmt_proc
        cmt
      end

      private

      def _init_stat(wdb)
        self[:stat] = Hashx.new
        wdb[:index].each do |id, evnt|
          hash = self[:stat].get(id) { Hashx.new }
          hash[:label] = evnt[:label]
          _init_cond(evnt[:cnd], hash.get(:cond) { [] })
        end
        self
      end

      def _init_cmt_proc
        init_time2cmt(@event)
        @cmt_procs << proc do
          @event.upd
          %i(exec block int act_time upd_next).each do |id|
            self[id] = @event.get(id)
          end
          _upd_stat
        end
      end

      def _init_cond(cond, m)
        cond.each do |cnd|
          m << (h = Hashx.new(cnd))
          _init_by_type(cnd, h)
        end
        self
      end

      def _init_by_type(cnd, h)
        case cnd[:type]
        when 'onchange'
          nil
        when 'compare'
          h[:vals] = []
        else
          h[:cri] = cnd[:val]
        end
      end

      def _upd_stat
        self[:stat].each do |id, v|
          _upd_cond(id, v[:cond])
          v[:active] = @event.get(:active).include?(id)
        end
        self
      end

      def _upd_cond(id, conds)
        conds.each_with_index do |cnd, i|
          cnd[:res] = (@event.get(:res)[id] || [])[i]
          idx = @event.get(:crnt)
          _upd_by_type(cnd, idx)
        end
        self
      end

      def _upd_by_type(cnd, idx)
        v = cnd[:var]
        case cnd[:type]
        when 'onchange'
          cnd[:val] = idx[v]
          cnd[:cri] = @event.get(:last)[v]
        when 'compare'
          cnd[:vals] = cnd[:vars].map { |k| "#{k}:#{idx[k]}" }
        else
          cnd[:val] = idx[v]
        end
      end
    end

    if __FILE__ == $PROGRAM_NAME
      require 'libinsdb'
      GetOpts.new('[site] | < event_file', 'r') do |_opt|
        event = Event.new
        wview = View.new(event)
        event.ext_local_file if STDIN.tty?
        puts wview.cmt
      end
    end
  end
end
