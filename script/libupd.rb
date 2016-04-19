#!/usr/bin/ruby
require 'libenumx'
module CIAX
  # Variables with update feature
  # Used for convert or loading as client from lower layer data.
  # All data manipulation command should include upd.
  class Upd < Hashx
    attr_reader :upd_procs, :cmt_procs
    def initialize
      super()
      self[:time] = now_msec
      # Proc Array for Pre-Process of Update Propagation to the upper Layers
      @upd_procs = []
      # Proc Array for Commit Propagation to the upper Layers
      @cmt_procs = []
    end

    # Time setting, Loading file at client
    def upd
      @upd_procs.each { |p| p.call(self) }
      verbose { "Update(#{time_id}) Pre Procs" }
      self
    end

    # Data Commit Method
    # For trigger of data storing or processing propagation to upper layer
    def cmt
      @cmt_procs.each { |p| p.call(self) }
      verbose { "Commiting(#{time_id})" }
      self
    end

    ## Manipulate data
    def put(key, val)
      super || return
      time_upd
      cmt
    end

    def repl(key, val)
      super || return
      time_upd
      cmt
    end

    # Generate new data by input
    def make
      time_upd
      cmt
    end

    # Time Updater
    def time_upd(tm = nil)
      self[:time] = tm || now_msec
      self
    end

    def time_id
      self[:time].to_s[-6, 6]
    end
  end
end
