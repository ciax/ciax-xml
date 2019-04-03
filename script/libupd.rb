#!/usr/bin/env ruby
require 'libhashx'
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
      @upd_procs = ProcArray.new(self, :upd)
      # Proc Array for Commit Propagation to the upper Layers
      @cmt_procs = ProcArray.new(self, :cmt)
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
      verbose { "Time Updated #{self[:time]}" }
      self
    end

    def time_id
      self[:time].to_s[-6, 6]
    end

    # Set time_upd to @cmt_procs with lower layer time
    def init_time2cmt(stat = nil)
      if stat
        @cmt_procs.append(self, :time, 0) { time_upd(stat[:time]) }
      else
        @cmt_procs.append(self, :time, 0) { time_upd }
      end
      self
    end

    def propagation(obj)
      @upd_procs.append(obj, :upd) do
        verbose { __ppg_verstr(self, obj, 'UPD') }
        obj.upd
      end
      obj.cmt_procs.append(self, :cmt, 4) do |o|
        verbose { __ppg_verstr(o, self, 'CMT') }
        cmt
      end
      self
    end

    private

    def __ppg_verstr(src, dst, way)
      fmt = "#{way} Propagate %s -> %s from %s"
      ca = caller.grep_v(/lib(upd|msg)/).first.split('/').last.tr("'`", '')
      format(fmt, src.base_class, dst.base_class, ca)
    end
  end
end
