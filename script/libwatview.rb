#!/usr/bin/ruby
require 'libwatrsp'

# View is not used for computing, just for apperance for user.
# So the convert process (upd_view) will be included in to_s
module CIAX
  # Watch Layer
  module Wat
    # Decorate the event data (Put caption,symbole,etc.) from WDB
    class View < Upd
      def initialize(event)
        super()
        @event = type?(event, Event)
        wdb = type?(event.dbi, Dbi)[:watch]
        init_stat(wdb || { index: [] })
        upd
      end

      private

      def init_stat(wdb)
        self[:stat] = Hashx.new
        wdb[:index].each do |id, evnt|
          hash = self[:stat].get(id) { Hashx.new }
          hash[:label] = evnt[:label]
          init_cond(evnt[:cnd], hash.get(:cond) { [] })
        end
        self
      end

      def init_cond(cond, m)
        cond.each do |cnd|
          m << (h = Hashx.new(cnd))
          _init_by_type(cnd, h)
        end
        self
      end

      def _init_by_type(cnd, h)
        case cnd[:type]
        when 'onchange'
        when 'compare'
          h[:vals] = []
        else
          h[:cri] = cnd[:val]
        end
      end

      def upd_core
        self[:time] = @event[:time]
        %i(exec block int act_time upd_next).each do |id|
          self[id] = @event.get(id)
        end
        upd_stat
        self
      end

      def upd_stat
        self[:stat].each do |id, v|
          upd_cond(id, v[:cond])
          v[:active] = @event.get(:active).include?(id)
        end
        self
      end

      def upd_cond(id, conds)
        conds.each_with_index do |cnd, i|
          cnd[:res] = (@event.get(:res)[id] || [])[i]
          idx = @event.get(:crnt)
          _upd_by_type(cnd, idx)
        end
        self
      end

      def _upd_by_type(cnd, idx)
        case cnd[:type]
        when 'onchange'
          v = cnd[:var]
          cnd[:val] = idx[v]
          cnd[:cri] = @event.get(:last)[v]
        when 'compare'
          cnd[:vals] = cnd[:vars].map { |k| "#{k}:#{idx[k]}" }
        end
      end
    end

    if __FILE__ == $PROGRAM_NAME
      require 'libinsdb'
      GetOpts.new('[site] | < event_file', 'r') do |_opt|
        event = Event.new
        wview = View.new(event)
        event.ext_file if STDIN.tty?
        puts wview
      end
    end
  end
end
