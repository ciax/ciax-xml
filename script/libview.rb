#!/usr/bin/env ruby
require 'libpath'
require 'libopt'
module CIAX
  module View
    # view mode change
    module Mode
      include Path
      @default_view = 'v'

      def to_s
        return to_j unless STDOUT.tty?
        @vmode ||= Mode.default_view
        method("to_#{@vmode}").call
      rescue NameError
        super
      end

      def to_j
        JSON.pretty_generate(self)
      end

      def to_r
        Struct.new(self).to_s
      end

      def to_v
        to_r
      end

      def to_o # original data
        to_r
      end

      # For Exe @def_proc
      def vmode(mode)
        @vmode = mode || Mode.default_view
        self
      end

      def self.default_view
        @default_view
      end
    end
  end

  module Opt
    # Adding View mode option to Opt
    module Chk
      private

      # Set view mode procs
      def ___set_opt(str)
        %i(j r).each do |k|
          @optdb[k][:proc] = proc do
            View.default_view.replace(k.to_s)
          end
        end
        super
      end
    end
  end
end
