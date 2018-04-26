#!/usr/bin/ruby
require 'librecord'

module CIAX
  # Macro Layer
  module Mcr
    # Record Archive List (Dir)
    class RecList < Varx
      attr_reader :records
      def initialize(id = 'mcr')
        super('rec', 'list')
        ext_local_file.load
        @id = id
        # @archives : Archive List : Index of Record (id: cid,pid,res)
        @archives = (self[:list] ||= {})
        # @records : Visible List : Database of Record (Part of archive)
        @records = Hashx.new
        init_time2cmt
        auto_save
      end

      # Re-generate record list
      def refresh # returns self
        verbose { 'Initiate Record List' }
        Dir.glob(vardir('record') + 'record_*.json') do |name|
          next if /record_([0-9]+).json/ !~ name
          next if @archives.key?(Regexp.last_match(1))
          push(___jread(name))
        end
        cmt
        self
      end

      # For format changes
      def clear
        @archives.clear
        self
      end

      # delete from @records other than in ary
      def flush(ary)
        (@records.keys - ary).each do |id|
          @records.delete(id)
        end
        self
      end

      def push(record) # returns self
        id = record[:id]
        return self unless id.to_i > 0
        ele = Hashx.new(record).pick(%i(cid pid result)) # extract header
        if record.is_a?(Record)
          ___init_record(record)
          @records[id] = record
        end
        @archives[id] = ele
        self
      end

      #### Client Methods ####
      def ext_http(host)
        @host = host
        self
      end

      def upd
        @records.values.each(&:upd)
        self
      end

      def get(id)
        type?(id, String)
        @records.get(id) { |key| Record.new(key).ext_http(@host, 'record') }
      end

      private

      def ___init_record(record)
        record.cmt_procs << proc do
          verbose { 'Propagate Record#cmt -> RecList#cmt' }
          cmt
        end
      end

      def ___jread(fname)
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

    puts RecList.new.clear.refresh if __FILE__ == $PROGRAM_NAME
  end
end
