#!/usr/bin/ruby
require 'librepeat'
require 'libdb'

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
        idx = wdb[:index] = {}
        _get_wdb(wdoc, reg, idx, db[:command][:group])
        reg[:exec] << ['upd'] if reg[:exec].empty?
      end

      private

      def _get_wdb(wdoc, reg, idx, cgrp)
        Repeat.new.each(wdoc) do|e0, r0|
          case e0.name
          when 'regular'
            _make_regular(e0, reg)
          when 'event'
            _make_event(e0, r0, idx, cgrp)
          end
        end
      end

      def _make_regular(e0, reg)
        reg.update(e0.to_h)
        e0.each do|e1|
          args = [e1[:name]]
          e1.each do|e2|
            args << e2.text
          end
          reg[:exec] << args
        end
      end

      def _make_event(e0, r0, idx, cgrp)
        id = e0.attr2item(idx) { |_, v| r0.formatting(v) }
        item = idx[id]
        cnd = item[:cnd] = []
        act = item[:act] = {}
        e0.each do|e1|
          _event_element(e1, r0, act, cnd, cgrp)
        end
      end

      def _event_element(e1, r0, act, cnd, cgrp)
        case name = e1.name.to_sym
        when :block, :int, :exec
          (act[name] ||= []) << _make_action(e1, r0)
        when :block_grp
          (act[:block] ||= []).concat(_make_block(e1, cgrp))
        when :compare
          cnd << _make_cond(e1, r0).update(vars: e1.map { |e2| e2[:var] })
        else
          cnd << _make_cond(e1, r0)
        end
      end

      def _make_action(e1, r0)
        # e1[:name] is different from e1.name (attribute vs. tag)
        args = [e1[:name]]
        e1.each { |e2| args << r0.subst(e2.text) }
        args
      end

      def _make_block(e1, cgrp)
        cgrp[e1[:ref]][:members].map { |k| [k] }
      end

      def _make_cond(e1, r0)
        h = e1.to_h
        h.each_value { |v| v.replace(r0.formatting(v)) }
        h.update(type: e1.name)
      end
    end
  end
end
