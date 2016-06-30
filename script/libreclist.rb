#!/usr/bin/ruby
require 'librecord'

module CIAX
  # Macro Layer
  module Mcr
    # Record List (Dir)
    class RecList < Varx
      def initialize
        super('rec', 'list')
        ext_local_file.load
        @list = (self[:list] ||= [])
        @active = {}
        auto_save
      end

      def refresh
        @list.clear
        verbose { 'Initiate Record List' }
        Dir.glob(vardir('record') + 'record_*.json') do |name|
          next if /record_[0-9]+.json/ !~ name
          add(_jread(name))
        end
        cmt
        self
      end

      def add(record)
        hash = Hashx.new(type?(record, Hash))
        _init_record(record)
        id = hash[:id]
        return unless id.to_i > 0
        ele = hash.pick(%i(id cid result))
        @active[id] = ele
        @list << ele
        cmt
      end

      private

      def _init_record(record)
        return unless record.is_a? Record
        record.cmt_procs << proc do
          verbose { 'Propagate Record#cmt -> RecList#cmt' }
          @active[record[:id]][:result] = record[:result]
          cmt
        end
      end

      def _jread(fname)
        j2h(
          open(fname) do |f|
            f.flock(::File::LOCK_SH)
            f.read
          end
        )
      rescue Errno::ENOENT, UserError
        verbose { "  -- no json file (#{fname})" }
        Hashx.new
      end
    end

    puts RecList.new.refresh if __FILE__ == $PROGRAM_NAME
  end
end
