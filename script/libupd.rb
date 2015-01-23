#!/usr/bin/ruby
require 'libenumx'
module CIAX
  # Variables with update feature
  class Upd < Hashx
    attr_reader :pre_upd_procs,:post_upd_procs
    def initialize
      super()
      # Updater
      @pre_upd_procs=[] # Proc Array for Pre-Process of Update Propagation to the upper Layers
      @post_upd_procs=[] # Proc Array for Post-Process of Update Propagation to the upper Layers
    end

    # update after processing, never iniherit (use upd_core() instead)
    def upd
      pre_upd # Loading file at client
      verbose("Upd","UPD_PROC for [#{@type}:#{self['id']}]")
      upd_core # Data conversion
      self
    ensure
      post_upd # Save & Update super layer
    end

    def to_s
      if self.class.method_defined?(:to_v)  && @vmode=='v'
        to_v
      else
        super
      end
    end

    private
    def pre_upd
      @pre_upd_procs.each{|p| p.call(self)}
      self
    end

    # Inherit upd_core() for upd function
    def upd_core
      self
    end

    def post_upd
      @post_upd_procs.each{|p| p.call(self)}
      self
    end
  end
end
