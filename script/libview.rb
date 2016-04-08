#!/usr/bin/ruby
require 'libpath'
module CIAX
  # show_iv = Show Instance Variable
  module View
    include ViewPath

    def to_s
      return to_j unless STDOUT.tty?
      case @vmode
      when 'v'
        to_v
      when 'j'
        to_j
      when 'r'
        to_r
      when 'o'
        to_o
      else
        super
      end
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
