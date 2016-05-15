#!/usr/bin/ruby
require 'libvarx'

module CIAX
  # Macro Layer
  module Mcr
    # Record List (Dir)
    class RecList < Varx
      def initialize
        super('rec', 'list')
        @list = self[:list] = Hashx.new
        ext_local_file
      end

      def refresh
        @list.clear
        Dir.glob(vardir('json') + 'record_*.json') do |name|
          next if /record_[0-9]+.json/ !~ name
          add(jread(name))
        end
        save
        self
      end

      def add(hash)
        type?(hash, Hash)
        @list[hash[:id]] = [hash[:cid], hash[:result]] if hash[:id].to_i > 0
        self
      end

      private

      def jread(fname)
        j2h(
          open(fname) do|f|
            f.flock(::File::LOCK_SH)
            f.read
          end
        )
      rescue Errno::ENOENT, UserError
        verbose { "  -- no json file (#{fname})" }
        Hashx.new
      end
    end
  end
end
