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
        init_time2cmt
        auto_save
      end

      def refresh # returns self
        @list.clear
        verbose { 'Initiate Record List' }
        Dir.glob(vardir('record') + 'record_*.json') do |name|
          next if /record_[0-9]+.json/ !~ name
          push(_jread(name))
        end
        cmt
        self
      end

      def push(record) # returns self
        id = record[:id]
        return self unless id.to_i > 0
        ele = Hashx.new(record).pick(%i(id cid result)) # extract header
        if record.is_a?(Record)
          _init_record(record)
          @active[id] = ele
        end
        @list << ele
        self
      end

      private

      def _init_record(record)
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
      rescue Errno::ENOENT, InvalidData
        verbose { "  -- no json file (#{fname})" }
        Hashx.new
      end
    end

    puts RecList.new.refresh if __FILE__ == $PROGRAM_NAME
  end
end
