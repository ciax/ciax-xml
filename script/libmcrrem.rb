#!/usr/bin/env ruby

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
          self
        end

        def batch
          idx = 0
          prev = @stat.to_json
          timeout = 3
          while timeout > 0
            sleep 1
            str = @stat.upd.to_v
            lines = str.split("\n").grep_v(/^ \(/)
            lines[idx..-1].each { |l| puts l }
            if prev == str.to_json
              timeout -= 1
            else
              prev = str.to_json
              idx = lines.size
              timeout = 3
            end
          end
          puts @stat.to_v.split("\n").last
          self
        end

        private

        def ___init_stat
          sid = @sv_stat.send(@cfg[:cid]).get(:sid)
          @stat = Record.new(sid).ext_remote(@host)
          @stat.upd_procs.append(self, 'remote') do
            @valid_keys.replace(@stat[:option].to_a)
          end
          @int.pars.add_num(sid)
        end
      end
    end
  end
end
