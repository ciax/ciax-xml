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
      @upd_procs = ProcArray.new(self, :upd, 'Updating')
      # Proc Array for Commit Propagation to the upper Layers
      @cmt_procs = ProcArray.new(self, :cmt, 'Committing', 5)
    end

    # Time setting, Loading file at client
    # For loading with propagation
    # Should be done when pulling data
    def upd
      @upd_procs.call
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
      self
    end

    ## Manipulate data
    def put(key, val)
      super { cmt }
    end

    def repl(key, val)
      super { cmt }
    end

    def del(*keyary)
      super { cmt }
    end

    # Time Updater
    def time
      self[:time]
    end

    # Takes [:time] from hash
    def time_upd(hash = nil)
      self[:time] = (hash.time if hash.is_a?(Upd)) || now_msec
      verbose { ___time_text(hash ? 'Updated' : 'Generated') }
      self
    end

    def time_id
      Msg.uptime(self[:time])
    end

    # Set time_upd to @cmt_procs with lower layer time
    def init_time2cmt
      @cmt_procs.append(self, :time, 0) { time_upd }
      self
    end

    # Returns argument
    def propagation(obj, updid = nil)
      @upd_procs.append(self, updid) { obj.upd } if updid
      obj.cmt_procs.append(self, "cmt(#{@id})", 4) do |o|
        # Update self[:time]
        time_upd(o)
        verbose { ___ppg_text(o, self) }
        cmt
      end
      obj
    end

    ### Display methods
    def to_j
      upd
      super
    end

    def to_r
      upd
      super
    end

    def path(ary = [])
      upd
      super
    end

    private

    def ___time_text(str)
      cfmt('Timestamp %s %s (%s)', str, elps_sec(time), time_id)
    end

    def ___ppg_text(src, dst)
      fmt = 'Propagate %s -> %s from %s'
      # Cant use grep_v on Ver 2.0.0
      ca = caller.reject do |s|
        /lib(upd|msg)/ =~ s
      end.first.split('/').last.tr("'`", '')
      cfmt(fmt, src.base_class, dst.base_class, ca)
    end
  end
end
