#!/usr/bin/ruby
require 'libenumx'
module CIAX
  # Variables with update feature
  class Upd < Hashx
    attr_reader :pre_upd_procs, :post_upd_procs
    def initialize
      super()
      # Updater
      # Proc Array for Pre-Process of Update Propagation to the upper Layers
      @pre_upd_procs = []
      # Proc Array for Post-Process of Update Propagation to the upper Layers
      @post_upd_procs = []
    end

    # update after processing, never iniherit (use upd_core() instead)
    def upd
      pre_upd
      upd_core || warning('No core_upd')
      verbose { "Update(#{_time_id}) Core" }
      self
    ensure
      post_upd
    end

    def read(json_str = nil)
      pre_upd
      super
    ensure
      post_upd
    end

    def put(key, val)
      pre_upd
      super
    ensure
      post_upd
    end

    private

    # Time setting, Loading file at client
    def pre_upd
      @pre_upd_procs.each { |p| p.call(self) }
      verbose { "Update(#{_time_id}) Pre Procs" }
      self
    end

    # Data conversion
    # Inherit upd_core() for upd function
    def upd_core; end

    # Save & Update super layer
    def post_upd
      @post_upd_procs.each { |p| p.call(self) }
      verbose { "Update(#{_time_id}) Post Procs" }
      self
    end

    def _time_id
      self['time'].to_s[-6, 6]
    end
  end
end
