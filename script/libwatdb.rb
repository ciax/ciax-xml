#!/usr/bin/env ruby
require 'libdbtree'

module CIAX
  # Watch Layer
  module Wat
    # Watch DB
    module Db
      # structure
      #   exec  = [cond1, 2, ...]
      #   cond  = [args1, 2, ..]
      #   args1 = ['cmd', 'par1', ..]
      def _init_watch(doc, db)
        return {} unless doc.key?(:watch)
        wdoc = doc[:watch]
        wdb = db[:watch] = wdoc.to_h
        reg = wdb[:regular] = { period: 300, exec: [] }
        idx = wdb[:index] = Hashx.new
        ___get_wdb(wdoc, reg, idx, db[:command][:group])
        reg[:exec] << ['upd'] if reg[:exec].empty?
      end

      private

      def ___get_wdb(wdoc, reg, idx, cgrp)
        @rep.each(wdoc) do |e0|
          case e0.name
          when 'regular'
            ___make_regular(e0, reg)
          when 'event'
            ___make_event(e0, idx, cgrp)
          end
        end
      end

      def ___make_regular(e0, reg)
        reg.update(e0.to_h)
        e0.each do |e1|
          args = [e1[:name]]
          e1.each do |e2|
            args << e2.text
          end
          reg[:exec] << args
        end
      end

      def ___make_event(e0, idx, cgrp)
        id = e0.attr2item(idx) { |v| @rep.formatting(v) }
        item = idx[id]
        cnd = item[:cnd] = []
        act = item[:act] = Hashx.new
        e0.each do |e1|
          ___event_element(e1, act, cnd, cgrp)
        end
      end

      def ___event_element(e1, act, cnd, cgrp)
        case name = e1.name.to_sym
        when :block, :int, :exec
          act.get(name) { [] } << ___make_action(e1)
        when :block_grp
          act.get(:block) { [] }.concat(___make_block(e1, cgrp))
        else
          cnd << ___make_cond(e1, name == :compare)
        end
      end

      def ___make_action(e1)
        # e1[:name] is different from e1.name (attribute vs. tag)
        args = [e1[:name]]
        e1.each { |e2| args << @rep.subst(e2.text) }
        args
      end

      def ___make_block(e1, cgrp)
        ref = e1[:ref]
        rgrp = cgrp[ref] || cfg_err("No such ref [#{ref}]")
        rgrp[:members].map { |k| [k] }
      end

      def ___make_cond(e1, cmp = nil)
        h = e1.to_h
        h.each_value { |v| v.replace(@rep.formatting(v)) }
        h.update(vars: e1.map { |e2| e2[:var] }) if cmp
        h.update(type: e1.name)
      end
    end
  end
end
