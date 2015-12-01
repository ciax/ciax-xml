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
          @list |= v[:cnd].map { |i| i[:var] }
        end
      end

      # @event[:active] : Array of event ids which meet criteria
      # @event[:exec] : Command queue which contains commands issued as event
      # @event[:block] : Array of commands (units) which are blocked during busy
      # @event[:int] : List of interrupt commands which is effectie during busy
      def upd
        sync
        %i(active exec block int).each { |s| @event[s].clear }
        @windex.each do|id, item|
          next unless check(id, item)
          item[:act].each do|key, ary|
            if key == :exec
              ary.each do|args|
                @event[:exec] << ['event', 2, args]
              end
            else
              @event.fetch(key).concat(ary)
            end
          end
          @event.fetch(:active) << id
        end
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
          vn = ckitm[:var]
          val = @stat[:data][vn]
          case ckitm[:type]
          when 'onchange'
            cri = @event[:last][vn]
            if cri
              if (tol = ckitm[:tolerance])
                res = ((cri.to_f - val.to_f).abs > tol.to_f)
                verbose do
                  format('  onChange(%s): |[%s]-<%s>| > %s =>%s',
                         vn, cri, val, tol, res.inspect)
                end
              else
                res = (cri != val)
                verbose do
                  format('  onChange(%s): [%s] vs <%s> =>%s',
                         vn, cri.inspect, val, res.inspect)
                end
              end
            else
              res = false
            end
          when 'pattern'
            cri = ckitm[:val]
            res = Regexp.new(cri).match(val)
            verbose do
              format('  Pattern(%s): [%s] vs <%s> =>%s',
                     vn, cri, val, res.inspect)
            end
          when 'range'
            cri = ckitm[:val]
            f = format('%.3f', val.to_f)
            res = (ReRange.new(cri) == f)
            verbose do
              format('  Range(%s): [%s] vs <%s>(%s) =>%s',
                     vn, cri, f, val.class, res.inspect)
            end
          end
          res = !res if /true|1/ =~ ckitm[:inv]
          rary << res
        end
        @event[:res][id] = rary
        rary.all?
      end
    end
  end
end
