#!/usr/bin/env ruby
require 'libpath'
module CIAX
  # show_iv = Show Instance Variable
  module View
    include ViewPath
    @default_view = 'v'

    def to_s
      return to_j unless STDOUT.tty?
      @vmode ||= View.default_view
      method("to_#{@vmode}").call
    rescue NameError
      super
    end

    def to_j
      JSON.pretty_generate(self)
    end

    def to_r
      ViewStruct.new(self).to_s
    end

    def to_v
      to_r
    end

    def to_o # original data
      to_r
    end

    # For Exe @def_proc
    def vmode(mode)
      @vmode = mode ? mode : View.default_view
      self
    end

    def self.default_view
      @default_view
    end
  end
end
