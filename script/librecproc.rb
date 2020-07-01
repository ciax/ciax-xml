#!/usr/bin/env ruby
require 'librecord'
require 'libstepdev'

module CIAX
  # Macro Layer
  module Mcr
    # Add extend method in Record
    class Record
      # Local mode
      module Local
        include Varx::Local
        def ext_processor(cfg)
          extend(Processor).ext_processor(cfg)
        end
      end
      # Macro Response Module
      module Processor
        def self.extended(obj)
          Msg.type?(obj, Record)
        end

        # Level [0] Step, [1] Record & Item, [2] Group, [3] Domain, [4] Command
        # cfg(Entity) contains [:cid],['label'],@layers[:wat]
        # cfg doesn't change
        def ext_processor(cfg)
          @cfg = type?(cfg, Config)
          %i[port cid label].each { |k| self[k] = @cfg[k] }
          %i[version pid].each { |k| self[k] = @cfg[k] || '0' }
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
          cmt
        end

        def add_step(e1, depth) # returns Step
          step = Step.new(self[:start]).ext_processor(e1, depth, @opt)
          step.ext_device(@cfg[:dev_dic]) if @cfg.key?(:dev_dic)
          self[:steps] << step
          propagation(step)
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
