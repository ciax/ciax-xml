#!/usr/bin/ruby
require 'libpath'
module CIAX
  # show_iv = Show Instance Variable
  module View
    include ViewPath

    def to_s
      return to_j unless STDOUT.tty?
      case @vmode
      when :v
        to_v
      when :j
        to_j
      when :r
        to_r
      else
        super
      end
    end

    def to_j
      case self
      when Array
        JSON.dump(to_a)
      when Hash
        JSON.dump(to_hash)
      end
    end

    def to_r
      view_struct
    end

    def to_v
      to_r
    end

    # For Exe @def_proc
    def vmode(mode)
      @vmode = mode.to_sym if mode
      self
    end
  end
end
