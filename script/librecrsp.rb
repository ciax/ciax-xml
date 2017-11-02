#!/usr/bin/ruby
require 'librecord'
require 'libsteprsp'

module CIAX
  # Macro Layer
  module Mcr
    # Add extend method in Record
    class Record
      def ext_local_rsp(cfg)
        extend(Rsp).ext_local_rsp(cfg)
      end
      # Macro Response Module
      module Rsp
        def self.extended(obj)
          Msg.type?(obj, Record)
        end

        # Level [0] Step, [1] Record & Item, [2] Group, [3] Domain, [4] Command
        # cfg(Entity) contains [:cid],['label'],@layers[:wat]
        # cfg doesn't change
        def ext_local_rsp(cfg)
          @cfg = type?(cfg, Config)
          %i(port cid label).each { |k| self[k] = @cfg[k] }
          self[:ver] = @cfg[:version] || '0' # Version
          self[:total_steps] = 0
          @dummy = @cfg[:opt].test?
          self[:mode] = @dummy ? 'test' : 'drive'
          init_time2cmt
          self
        end

        def start
          self[:start] = now_msec
          title
        end

        def add_step(e1, depth) # returns Step
          step = Step.new(e1, depth, @dummy).ext_local_rsp(@cfg[:dev_list])
          self[:steps] << step.ext_prt(self[:start])
          step.cmt_procs << proc do
            verbose { 'Propagate Step#cmt -> Record#cmt' }
            cmt
          end
          step
        end

        def finish
          delete(:option)
          self[:total_time] = Msg.elps_sec(self[:start])
          self[:status] = 'end'
          self[:result]
        ensure
          cmt
        end
      end
    end
  end
end
