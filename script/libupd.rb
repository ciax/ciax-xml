#!/usr/bin/ruby
require 'libhashx'
module CIAX
  # Variables with update feature (also with manipulation)
  # Used for convert or loading as client from lower layer data.
  # All data manipulation command should include upd.
  class Upd < Hashx
    attr_reader :upd_procs, :cmt_procs
    def initialize
      super()
      time_upd
      # Proc Array for Pre-Process of Update Propagation to the upper Layers
      @upd_procs = []
      # Proc Array for Commit Propagation to the upper Layers
      @cmt_procs = []
    end

    # Time setting, Loading file at client
    # Should be done when pulling data
    def upd
      @upd_procs.each { |p| p.call(self) }
      verbose { "Update(#{time_id}) Pre Procs" }
      self
    end

    # Data Commit Method (Push type notification)
    # For trigger of data storing or processing propagation to upper layer
    # Should be executed when data processing will be done
    def cmt
      @cmt_procs.each { |p| p.call(self) }
      verbose { "Commiting(#{time_id})" }
      self
    end

    ## Manipulate data
    def put(key, val)
      super { cmt }
    end

    def repl(key, val)
      super { cmt }
    end

    def del(key)
      super { cmt }
    end

    # Update without any processing (Use for scan in macro)
    def latest
      self
    end

    # Time Updater
    def time_upd(tm = nil)
      self[:time] = tm || now_msec
      self
    end

    def time_id
      self[:time].to_s[-6, 6]
    end

    # Set time_upd to @cmt_procs with lower layer time
    def init_time2cmt(stat = nil)
      @cmt_procs << (stat ? proc { time_upd(stat[:time]) } : proc { time_upd })
      self
    end

    def upd_propagate(obj)
      @upd_procs << proc do
        verbose { "Propagate #{base_class}#upd -> #{obj.base_class}#upd" }
        obj.upd
      end
      self
    end

    def cmt_propagate(obj)
      obj.cmt_procs << proc do |o|
        verbose { "Propagate #{o.base_class}#cmt -> #{base_class}#cmt" }
        cmt
      end
      self
    end
  end
end
