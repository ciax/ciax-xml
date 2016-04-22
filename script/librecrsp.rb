#!/usr/bin/ruby
require 'librecord'
require 'libstep'
require 'libsteprsp'

module CIAX
  # Macro Layer
  module Mcr
    # Macro Response Module
    module RecRsp
      def self.extended(obj)
        Msg.type?(obj, Record)
      end

      # Level [0] Step, [1] Record & Item, [2] Group, [3] Domain, [4] Command
      # cfg will come from Entity, which contains [:cid],['label'],@layers[:wat]
      # cfg doesn't change
      def ext_rsp(cfg)
        @cfg = type?(cfg, Config)
        self[:ver] = @cfg[:version] || '0' # Version
        self[:cid] = @cfg[:cid] # Command ID (cmd:par)
        self[:label] = @cfg[:label] # Label for CID
        self[:total_steps] = 0
        @dummy = @cfg[:option].test?
        self
      end

      def start
        self[:start] = now_msec
        title
      end

      def add_step(e1, depth)
        step = StepRsp.new(@cfg[:dev_list], e1, depth, @dummy)
        self[:steps] << step.ext_prt(self[:start])
        step.cmt_procs << proc do
          verbose { 'Propagate Step#cmt -> Record#cmt' }
          cmt
        end
        step
      ensure
        cmt
      end

      def finish
        self[:total_time] = Msg.elps_sec(self[:time])
        self[:status] = 'end'
        self[:result]
      ensure
        cmt
      end
    end

    # Add extend method in Record
    class Record
      def ext_rsp(cfg)
        extend(Mcr::RecRsp).ext_rsp(cfg)
      end
    end
  end
end