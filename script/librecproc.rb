#!/usr/bin/ruby
require 'librecord'
require 'libstepdev'

module CIAX
  # Macro Layer
  module Mcr
    # Add extend method in Record
    class Record
      def ext_local_processor(cfg)
        extend(Processor).ext_local_processor(cfg)
      end
      # Macro Response Module
      module Processor
        def self.extended(obj)
          Msg.type?(obj, Record)
        end

        # Level [0] Step, [1] Record & Item, [2] Group, [3] Domain, [4] Command
        # cfg(Entity) contains [:cid],['label'],@layers[:wat]
        # cfg doesn't change
        def ext_local_processor(cfg)
          @cfg = type?(cfg, Config)
          %i(port cid label).each { |k| self[k] = @cfg[k] }
          self[:ver] = @cfg[:version] || '0' # Version
          self[:total_steps] = 0
          @opt = @cfg[:opt]
          self[:mode] = @opt.drv? ? 'drive' : 'test'
          init_time2cmt
          self
        end

        def start
          self[:start] = now_msec
          self[:status] = 'run'
          title_s
        end

        def add_step(e1, depth) # returns Step
          step = Step.new(self[:start]).ext_local_processor(e1, depth, @opt)
          step.ext_local_dev(@cfg[:dev_list]) if @cfg.key?(:dev_list)
          self[:steps] << step
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
