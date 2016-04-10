#!/usr/bin/ruby
require 'libevent'
require 'librerange'

module CIAX
  # Watch Layer
  module Wat
    # Watch Condition Class
    class Condition
      include Msg
      def initialize(windex, stat, event)
        @windex = type?(windex, Hash)
        @stat = type?(stat, App::Status)
        @event = type?(event, Event)
        # Pick usable val
        @list = []
        @windex.values.each do|v|
          @list |= v[:cnd].map { |i| i[:var] || i[:vars] }.flatten
        end
      end

      # @event[:active] : Array of event ids which meet criteria
      # @event[:exec] : Command queue which contains commands issued as event
      # @event[:block] : Array of commands (units) which are blocked during busy
      # @event[:int] : List of interrupt commands which is effectie during busy
      def upd
        sync
        %i(active exec block int).each { |s| @event[s].clear }
        _chk_conds
        @event
      end

      def sync
        @list.each do|i|
          @event[:last][i] = @event[:crnt][i]
          @event[:crnt][i] = @stat[:data][i]
        end
      end

      def check(id, item)
        return true unless (cklst = item[:cnd])
        verbose { "Check: <#{item[:label]}>" }
        rary = []
        cklst.each do|ckitm|
          res = _chk_by_type(ckitm)
          res = !res if /true|1/ =~ ckitm[:inv]
          rary << res
        end
        @event[:res][id] = rary
        rary.all?
      end

      private

      def _chk_conds
        @windex.each do|id, item|
          next unless check(id, item)
          _actives(item[:act])
          @event.fetch(:active) << id
        end
      end

      def _actives(act)
        act.each do|key, ary|
          if key == :exec
            ary.each do|args|
              @event[:exec] << ['event', 2, args]
            end
          else
            @event.fetch(key).concat(ary)
          end
        end
      end

      def _chk_by_type(ckitm)
        vn = ckitm[:var]
        name = "cnd_#{ckitm[:type]}"
        method(name).call(vn, ckitm)
      rescue NameError
        cfg_err("No such condition #{name}")
      end

      def cnd_onchange(vn, ckitm)
        tol = ckitm[:tolerance]
        val = @stat[:data][vn]
        cri = @event[:last][vn]
        return false unless cri
        if tol
          _cmp_tol(vn, cri, val, tol)
        else
          _cmp_just(vn, cri, val)
        end
      end

      def _cmp_tol(vn, cri, val, tol)
        res = ((cri.to_f - val.to_f).abs > tol.to_f)
        verbose do
          format('  onChange(%s): |[%s]-<%s>| > %s =>%s',
                 vn, cri, val, tol, res.inspect)
        end
        res
      end

      def _cmp_just(vn, cri, val)
        res = (cri != val)
        verbose do
          format('  onChange(%s): [%s] vs <%s> =>%s',
                 vn, cri, val, res.inspect)
        end
        res
      end

      def cnd_pattern(vn, ckitm)
        cri = ckitm[:val]
        val = @stat[:data][vn]
        res = (/#{cri}/ =~ val)
        verbose do
          format('  Pattern(%s): [%s] vs <%s> =>%s',
                 vn, cri, val, res.inspect)
        end
        res
      end

      def cnd_range(vn, ckitm)
        cri = ckitm[:val]
        val = @stat[:data][vn]
        f = format('%.3f', val.to_f)
        res = (ReRange.new(cri) == f)
        verbose do
          format('  Range(%s): [%s] vs <%s>(%s) =>%s',
                 vn, cri, f, val.class, res.inspect)
        end
        res
      end

      def cnd_compare(_vn, ckitm)
        vars = ckitm[:vars]
        vars.map { |vn| @stat[:data][vn] }.uniq.size == 1
      end
    end
  end
end
