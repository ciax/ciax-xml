#!/usr/bin/env ruby
require 'libmcrqry'

module CIAX
  # Macro Layer
  module Mcr
    # Macro Executor
    # Local mode only
    class Exe
      # Remote mode
      module Remote
        def self.extended(obj)
          Msg.type?(obj, Exe)
        end

        def ext_remote
          @mode = 'CL'
          _init_port
          _remote_sv_stat
          ___init_stat
          ___init_proc
          self
        end

        def batch
          @idx = 0
          tout = 3
          while tout > 0
            sleep 0.5
            tout = ___show_tail(tout) || 3
          end
          show_fg @all.last
          show_fg
          self
        end

        private

        def ___show_tail(timeout)
          str = @stat.upd.to_v
          @all = str.lines
          lines = @all.grep_v(/^ \(/)
          lines[@idx..-1].each { |l| __show l }
          @idx = lines.size
          return(timeout - 1) unless @qry.query || __diff(str)
        end

        def __diff(str)
          return false if @prev == str.to_json
          @prev = str.to_json
        end

        def __show(line)
          show_fg(/.+\?$/ =~ line ? line.chop : line)
        end

        def ___init_stat
          sid = @sv_stat.send(@cfg[:cid]).get(:sid)
          @stat = Record.new(sid).ext_remote(@host)
          @int.pars.add_num(sid)
          @qry = Query.new(@stat, @sv_stat, @valid_keys) do |cid|
            @sv_stat.send(format('%s:%s', cid, sid))
          end
        end

        def ___init_proc
          @stat.upd_procs.append(self, 'remote') do
            @valid_keys.replace(@stat[:option].to_a)
          end
        end
      end
    end
  end
end
