#!/usr/bin/ruby
require 'librecord'

module CIAX
  # Macro Layer
  module Mcr
    # Record Archive List (Dir)
    class RecArc < Varx
      attr_reader :records
      def initialize(id = 'mcr')
        super('rec', 'list')
        ext_local_file.load
        @id = id
        # @archives : Archive List : Index of Record (id: cid,pid,res)
        @archives = (self[:list] ||= {})
        # @records : Visible List : Database of Record (Part of archive)
        init_time2cmt
        auto_save
      end

      # Re-generate record list
      def refresh # returns self
        verbose { 'Initiate Record Archive' }
        ___file_list.each { |name| push(jload(name)) }
        cmt
        self
      end

      # For format changes
      def clear
        @archives.clear
        cmt
        self
      end

      def push(record) # returns self
        id = record[:id]
        return self unless id.to_i > 0
        ele = Hashx.new(record).pick(%i(cid pid result)) # extract header
        @archives[id] = ele
        cmt
        self
      end

      private

      def ___file_list
        ary = []
        Dir.glob(vardir('record') + 'record_*.json') do |name|
          next if /record_([0-9]+).json/ !~ name
          next if @archives.key?(Regexp.last_match(1))
          ary << name
        end
        ary
      end
    end

    puts RecArc.new.clear.refresh if __FILE__ == $PROGRAM_NAME
  end
end
