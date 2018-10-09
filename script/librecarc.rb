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
        ext_local_file
        init_time2cmt
        load_partial
      end

      def list
        self[:list] ||= {}
      end

      # Re-generate record list
      def refresh # returns self
        (___file_keys - list.keys).each { |key| push(jload(__rec_fname(key))) }
        verbose { 'Initiate Record Archive done' }
        cmt
      end

      def refresh_bg # returns self
        Threadx::Fork.new('RecArc(rec_list)', 'mcr', @id) do
          refresh
        end
      end

      # For format changes
      def clear
        list.clear
        cmt
      end

      def push(record) # returns self
        if record.is_a?(Record) && record[:id].to_i > 0
          if __extract(record) == 'busy'
            record.finish_procs << proc { |r| __extract(r) && cmt }
          end
          cmt
        end
        self
      end

      private

      def __extract(rec)
        ele = Hashx.new(rec).pick(%i(cid pid result)) # extract header
        return if ele.empty?
        verbose { 'Record Archive Updated' }
        list[rec[:id]] = ele
        ele[:result]
      end

      def ___file_keys
        ary = []
        Dir.glob(__rec_fname('*')) do |name|
          next if /record_([0-9]+).json/ !~ name
          ary << Regexp.last_match(1)
        end
        ary.sort.reverse
      end

      def __rec_fname(key)
        vardir('record') + "record_#{key}.json"
      end
    end

    RecArc.new.auto_save.refresh if __FILE__ == $PROGRAM_NAME
  end
end
