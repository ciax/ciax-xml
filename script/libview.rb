#!/usr/bin/ruby
require 'libpath'
module CIAX
  # show_iv = Show Instance Variable
  module View
    include ViewPath

    def to_s
      return to_j unless STDOUT.tty?
      method("to_#{@vmode}").call
    rescue NameError
      super
    end

    def to_j
      JSON.pretty_generate(self)
    end

    def to_r
      view_struct
    end

    def to_v
      to_r
    end

    def to_o # original data
      to_r
    end

    # For Exe @def_proc
    def vmode(mode)
      @vmode = mode if mode
      self
    end
  end
end
