#!/usr/bin/ruby
require 'libenumx'
module CIAX
  # Variables with update feature
  # Used for convert or loading as client from lower layer data.
  # All data manipulation command should include upd.
  class Upd < Hashx
    attr_reader :pre_upd_procs, :post_upd_procs
    def initialize
      super()
      time_upd
      # Proc Array for Pre-Process of Update Propagation to the upper Layers
      @pre_upd_procs = []
      # Proc Array for Post-Process of Update Propagation to the upper Layers
      @post_upd_procs = []
    end

    # update after processing, never iniherit (use upd_core() instead)
    def upd
      pre_upd
      upd_core || verbose { 'No upd_core' }
      verbose { "Update(#{time_id}) Core" }
      self
    ensure
      post_upd
    end

    ## Manipulate data
    def put(key, val)
      super || return
      time_upd
      post_upd
    end

    def repl(key, val)
      super || return
      time_upd
      post_upd
    end

    # Generate new data by input
    def make
      time_upd
      post_upd
    end

    # Time Updater
    def time_upd(tm = nil)
      self[:time] = tm || now_msec
      self
    end

    def time_id
      self[:time].to_s[-6, 6]
    end

    private

    # Time setting, Loading file at client
    def pre_upd
      @pre_upd_procs.each { |p| p.call(self) }
      verbose { "Update(#{time_id}) Pre Procs" }
      self
    end

    # Data conversion
    # Inherit upd_core() for upd function
    def upd_core; end

    # Save & Update super layer
    def post_upd
      @post_upd_procs.each { |p| p.call(self) }
      verbose { "Update(#{time_id}) Post Procs" }
      self
    end
  end
end
