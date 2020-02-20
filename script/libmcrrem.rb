#!/usr/bin/env ruby
require 'libclient'
require 'libmcrqry'

module CIAX
  # Macro Layer
  module Mcr
    # Macro Executor
    # Local mode only
    class Exe
      # Remote mode
      module Remote
        include CIAX::Exe::Remote

        TOUT = 10

        def self.extended(obj)
          Msg.type?(obj, Exe)
        end

        def ext_remote
          _remote_sv_stat
          ___init_stat
          _remote_stat
          super
        end

        def batch
          @idx = 0
          ___loop(TOUT)
          __show(@all.last)
          show_fg
          self
        end

        private

        def ___loop(tout)
          while tout > 0
            sleep 0.3
            tout = ___show_tail(tout) || TOUT
          end
        rescue Interrupt
          interrupt
        end

        def ___show_tail(timeout)
          str = @stat.upd.to_v
          @all = str.lines
          # V2.0 doesn't have grep_v()
          lines = @all.reject { |i| /^ \(/ =~ i }
          lines[@idx..-1].each { |l| __show l }
          @idx = lines.size
          return(timeout - 1) unless @qry.query || __diff(str)
        end

        def __diff(str)
          return false if @prev == str.to_json
          @prev = str.to_json
          dot
        end

        def __show(line)
          show_fg("\n" + line.chomp)
        end

        def ___init_stat
          sid = @sv_stat.send(@cfg[:cid]).get(:sid)
          @stat = Record.new(sid)
          @rem.int.pars.add_num(sid)
          @qry = Query.new(@stat, @sv_stat, @rem) do |cid|
            @sv_stat.send(format('%s:%s', cid, sid))
          end
        end
      end
    end
  end
end
