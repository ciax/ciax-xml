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
          idx = 0
          prev = @stat.to_json
          timeout = 3
          while timeout > 0
            sleep 0.5
            str = @stat.upd.to_v
            lines = str.split("\n").grep_v(/^ \(/)
            lines[idx..-1].each { |l| puts l }
            if prev == str.to_json
              @qry.query || timeout -= 1
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
