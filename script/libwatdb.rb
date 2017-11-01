#!/usr/bin/ruby
require 'libdbcmd'

module CIAX
  # Watch Layer
  module Wat
    # Watch DB
    module Db
      # structure
      #   exec  = [cond1, 2, ...]
      #   cond  = [args1, 2, ..]
      #   args1 = ['cmd', 'par1', ..]
      def init_watch(doc, db)
        return {} unless doc.key?(:watch)
        wdoc = doc[:watch]
        wdb = db[:watch] = wdoc.to_h
        reg = wdb[:regular] = { period: 300, exec: [] }
        idx = wdb[:index] = Hashx.new
        _get_wdb_(wdoc, reg, idx, db[:command][:group])
        reg[:exec] << ['upd'] if reg[:exec].empty?
      end

      private

      def _get_wdb_(wdoc, reg, idx, cgrp)
        @rep.each(wdoc) do |e0|
          case e0.name
          when 'regular'
            _make_regular_(e0, reg)
          when 'event'
            _make_event_(e0, idx, cgrp)
          end
        end
      end

      def _make_regular_(e0, reg)
        reg.update(e0.to_h)
        e0.each do |e1|
          args = [e1[:name]]
          e1.each do |e2|
            args << e2.text
          end
          reg[:exec] << args
        end
      end

      def _make_event_(e0, idx, cgrp)
        id = e0.attr2item(idx) { |v| @rep.formatting(v) }
        item = idx[id]
        cnd = item[:cnd] = []
        act = item[:act] = Hashx.new
        e0.each do |e1|
          _event_element_(e1, act, cnd, cgrp)
        end
      end

      def _event_element_(e1, act, cnd, cgrp)
        case name = e1.name.to_sym
        when :block, :int, :exec
          act.get(name) { [] } << _make_action_(e1)
        when :block_grp
          act.get(:block) { [] }.concat(_make_block_(e1, cgrp))
        else
          cnd << _make_cond(e1, name == :compare)
        end
      end

      def _make_action_(e1)
        # e1[:name] is different from e1.name (attribute vs. tag)
        args = [e1[:name]]
        e1.each { |e2| args << @rep.subst(e2.text) }
        args
      end

      def _make_block_(e1, cgrp)
        cgrp[e1[:ref]][:members].map { |k| [k] }
      end

      def _make_cond(e1, cmp = nil)
        h = e1.to_h
        h.each_value { |v| v.replace(@rep.formatting(v)) }
        h.update(vars: e1.map { |e2| e2[:var] }) if cmp
        h.update(type: e1.name)
      end
    end
  end
end
