#!/usr/bin/env ruby
require 'libwatstat'
require 'librerange'

module CIAX
  # Watch Layer
  module Wat
    # Watch Condition Class
    class Condition
      include Msg
      # @event[:active] : Array of event ids which meet criteria
      # @event[:exec] : Command queue which contains commands issued as event
      # @event[:block] : Array of commands (units) which are blocked during busy
      # @event[:int] : List of interrupt commands which is effectie during busy
      def initialize(windex, stat, event)
        @windex = type?(windex, Hash)
        @stat = type?(stat, App::Status)
        @event = type?(event, Event)
        # Pick usable val
        @list = []
        @windex.values.each do |v|
          @list |= v[:cnd].map { |i| i[:var] || i[:vars] }.flatten
        end
      end

      # Done every after Status updated
      def upd_cond
        ___sync
        %i[active exec block int].each { |s| @event[s].clear }
        ___chk_conds
        @event
      end

      private

      def ___sync
        @list.each do |i|
          hist = (@event[:history][i] ||= []).unshift(@stat[:data][i])
          hist.pop if hist.size > 3
        end
      end

      def ___chk_conds
        @windex.each do |id, item|
          next unless ___chk_item(id, item)
          ___actives(item[:act])
          (aary = @event.fetch(:active)) << id
          verbose { cfmt('Active conditions %p', aary) }
        end
      end

      def ___chk_item(id, item)
        return true unless (cklst = item[:cnd])
        verbose { cfmt('Check: <%s>(%p)', item[:label], item) }
        rary = []
        cklst.each do |ckitm|
          res = ___chk_by_type(ckitm)
          rary << (/true|1/ =~ ckitm[:inv] ? !res : res)
        end
        @event[:res][id] = rary
        rary.all?
      end

      def ___actives(act)
        act.each do |key, ary|
          if key == :exec
            ary.each do |args|
              @event[:exec] << ['event', 2, args]
            end
          else
            @event.fetch(key).concat(ary)
          end
        end
      end

      def ___chk_by_type(ckitm)
        vn = ckitm[:var]
        type = ckitm[:type]
        verbose { "Type #{type}" }
        name = "_cnd_#{ckitm[:type]}"
        method(name).call(vn, ckitm)
      rescue NameError
        cfg_err("No such condition #{name}")
      end

      def _cnd_onchange(vn, ckitm)
        tol = ckitm[:tolerance]
        hist = @event[:history][vn]
        val = hist[0]
        cri = hist[1]
        return false unless cri
        if tol
          ___cmp_tol(cri, val, tol)
        else
          ___cmp_just(cri, val)
        end
      end

      def ___cmp_tol(cri, val, tol)
        res = ((cri.to_f - val.to_f).abs > tol.to_f)
        # verbose do
        #   format('  onChange(%s): |[%s]-<%s>| > %s =>%s',
        #          vn, cri, val, tol, res.inspect)
        # end
        res
      end

      def ___cmp_just(cri, val)
        res = (cri != val)
        # verbose do
        #   format('  onChange(%s): [%s] vs <%s> =>%s',
        #          vn, cri, val, res.inspect)
        # end
        res
      end

      def _cnd_pattern(vn, ckitm)
        cri = ckitm[:val]
        val = @stat[:data][vn]
        res = (/#{cri}/ =~ val ? true : false)
        # verbose do
        #  format('  Pattern(%s): [%s] vs <%s> =>%s',
        #         vn, cri, val, res.inspect)
        # end
        res
      end

      def _cnd_range(vn, ckitm)
        cri = ckitm[:val]
        val = @stat[:data][vn]
        f = format('%.3f', val.to_f)
        res = (ReRange.new(cri) == f)
        # verbose do
        #   format('  Range(%s): [%s] vs <%s>(%s) =>%s',
        #          vn, cri, f, val.class, res.inspect)
        # end
        res
      end

      def _cnd_compare(_vn, ckitm)
        vars = ckitm[:vars]
        vars.map { |vn| @stat[:data][vn] }.uniq.size == 1
      end
    end
  end
end
