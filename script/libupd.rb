#!/usr/bin/env ruby
require 'libprocary'
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
      @upd_procs = ProcArray.new(self)
      # Proc Array for Commit Propagation to the upper Layers
      @cmt_procs = ProcArray.new(self)
    end

    # Add cmt for self return method
    def deep_update(ope)
      super
      cmt
    end

    # Time setting, Loading file at client
    # For loading with propagation
    # Should be done when pulling data
    def upd
      @upd_procs.call
      verbose { "Update(#{time_id}) Pre Procs" }
      self
    end

    # Data Commit Method (Push type notification)
    # For trigger of data storing or processing propagation to upper layer
    # Should be executed when data processing will be done
    # Execution order:
    #  - Time setting (sync to lower data time)
    #  - Save File
    #  - Logging
    #  - Exec Upper data cmt
    def cmt
      @cmt_procs.call
      verbose { "Commiting(#{time_id})" + @cmt_procs.view.inspect }
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

    def propagation(obj)
      @upd_procs << proc do
        __propagate_ver(self, obj, 'UPD')
        obj.upd
      end
      obj.cmt_procs << proc do |o|
        __propagate_ver(o, self, 'CMT')
        cmt
      end
      self
    end

    private

    def __propagate_ver(src, dst, way)
      verbose do
        fmt = "#{way} Propagate %s -> %s from %s"
        ca = caller.grep_v(/lib(upd|msg)/).first.split('/').last.tr("'`", '')
        format(fmt, src.base_class, dst.base_class, ca)
      end
    end
  end
end
