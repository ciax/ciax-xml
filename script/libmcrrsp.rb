#!/usr/bin/ruby
require 'librecord'
require 'libstep'

module CIAX
  # Macro Layer
  module Mcr
    # Macro Response Module
    module Rsp
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
        self
      end

      def start
        self[:start] = now_msec.to_s
        title
      end

      def add_step(e1, depth)
        step = Step.new(e1, @cfg[:dev_list], @cfg[:option].test?)
        step.post_upd_procs << proc do
          verbose { 'Propagate Step#upd -> Record#upd' }
          post_upd
        end
        step[:depth] = depth
        self[:steps] << step
        step
      ensure
        post_upd
      end

      def finish
        self[:total_time] = Msg.elps_sec(self[:time])
        self[:status] = 'end'
        self[:result]
      ensure
        post_upd
      end
    end

    # Add extend method in Record
    class Record
      def ext_rsp(cfg)
        extend(Mcr::Rsp).ext_rsp(cfg)
      end
    end
  end
end
