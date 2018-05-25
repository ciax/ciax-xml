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
        ext_local_file
        @id = id
        # @list : Archive List : Index of Record (id: cid,pid,res)
        @list = (self[:list] ||= {})
        init_time2cmt
        auto_save
      end

      # Re-generate record list
      def refresh # returns self
        Threadx::Fork.new('RecArc(rec_list)', 'mcr', @id) do
          ___file_list.each { |name| push(jload(name)) }
          verbose { 'Initiate Record Archive done' }
        end
      end

      # For format changes
      def clear
        @list.clear
        cmt
      end

      def push(record) # returns self
        if record[:id].to_i > 0 && extract(record) && record.is_a?(Record)
          record.finish_procs << proc { |r| extract(r) }
        end
        self
      end

      def extract(rec)
        ele = Hashx.new(rec).pick(%i(cid pid result)) # extract header
        return if ele.empty?
        verbose { 'Record Archive Updated' }
        @list[rec[:id]] = ele
        cmt
      end

      private

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

    puts RecArc.new.clear.refresh.join if __FILE__ == $PROGRAM_NAME
  end
end
