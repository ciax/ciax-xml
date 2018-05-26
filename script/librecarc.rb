#!/usr/bin/ruby
require 'librecord'
require 'libthreadx'
module CIAX
  # Macro Layer
  module Mcr
    # Record Archive List (Dir)
    #   Index of Records
    class RecArc < Varx
      attr_reader :list, :id
      def initialize(id = 'mcr')
        super('rec', 'list')
        @id = id
        # @list : Archive List : Index of Record (id: cid,pid,res)
        @list = (self[:list] ||= {})
      end

      # Re-generate record list
      def refresh # returns self
        Threadx::Fork.new('RecArc(rec_list)', 'mcr', @id) do
          ___file_list.each { |name| push(jload(name)) }
          verbose { 'Initiate Record Archive done' }
          cmt
        end
      end

      # For format changes
      def clear
        @list.clear
        cmt
      end

      def push(record) # returns self
        if record[:id].to_i > 0 && __extract(record) && record.is_a?(Record)
          record.finish_procs << proc { |r| __extract(r) && cmt }
          cmt
        end
        self
      end

      def ext_local_driver
        ext_local_file
        init_time2cmt
        auto_save
        load
      end

      private

      def __extract(rec)
        ele = Hashx.new(rec).pick(%i(cid pid result)) # extract header
        return if ele.empty?
        verbose { 'Record Archive Updated' }
        @list[rec[:id]] = ele
      end

      def ___file_list
        ary = []
        Dir.glob(vardir('record') + 'record_*.json') do |name|
          next if /record_([0-9]+).json/ !~ name
          next if @list.key?(Regexp.last_match(1))
          ary << name
        end
        ary.sort.reverse
      end
    end

    if __FILE__ == $PROGRAM_NAME
      puts RecArc.new.ext_local_driver.clear.refresh.join
    end
  end
end
