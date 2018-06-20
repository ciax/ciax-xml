#!/usr/bin/ruby
require 'librecord'
require 'libstepdev'

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
          @opt = @cfg[:opt]
          self[:mode] = @opt.log? ? 'drive' : 'test'
          init_time2cmt
          self
        end

        def start
          self[:start] = now_msec
          title_s
        end

        def add_step(e1, depth) # returns Step
          step = Step.new(self[:start]).ext_local_drv(e1, depth, @opt)
          self[:steps] << step.ext_local_rsp(@cfg[:dev_list])
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
          self[:result] = @result
        ensure
          @finish_procs.each { |p| p.call(self) }
          cmt
        end
      end
    end
  end
end
