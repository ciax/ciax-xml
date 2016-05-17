#!/usr/bin/ruby
require 'libvarx'

module CIAX
  # Macro Layer
  module Mcr
    # Record List (Dir)
    class RecList < Varx
      def initialize
        super('rec', 'list')
        @list = self[:list] = []
        @current = {}
        ext_local_file
        @cmt_procs << proc { time_upd }
        auto_save
      end

      def refresh
        @list.clear
        Dir.glob(vardir('json') + 'record_*.json') do |name|
          next if /record_[0-9]+.json/ !~ name
          add(jread(name))
        end
        cmt
        self
      end

      def add(record)
        hash = Hashx.new(type?(record, Hash))
        _init_record(record)
        return unless hash[:id].to_i > 0
        @current = hash.pick(%i(id cid result))
        @list << @current
        cmt
      end

      private

      def _init_record(record)
        return unless record.is_a? Record
        record.cmt_procs << proc do
          verbose { 'Propagate Record#cmt -> RecList#cmt' }
          @current[:result] = record[:result]
          cmt
        end
      end

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
