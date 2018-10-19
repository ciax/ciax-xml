#!/usr/bin/ruby
require 'librecord'
require 'libthreadx'
module CIAX
  # Macro Layer
  module Mcr
    # Record Archive List (Dir)
    #   Index of Records
    class RecArc < Varx
      attr_reader :list
      def initialize
        super('list', 'record')
        # @list : Archive List : Index of Record (id: cid,pid,res)
      end

      def list
        self[:list] ||= {}
      end

      # Mode
      #   Skelton
      #   Remote (Read only)
      #   Local  (Read/Write Memory)
      #   Local_File (Read/Write Memory, File read only)
      #   Local_Save (Read/Write File)
      def ext_local
        extend(Local).ext_local
      end

      # Macro Response Module
      module Local
        def self.extended(obj)
          Msg.type?(obj, RecArc)
        end

        def ext_local
          init_time2cmt
          ext_local_file.load
          auto_save
          self
        end

        def push(record) # returns self
          if record.is_a?(Hash) && record[:id].to_i > 0
            if __extract(record) == 'busy' && record.is_a?(Record)
              record.finish_procs << proc { |r| __extract(r) && cmt }
            end
          end
          self
        end

        # For format changes
        def clear
          list.clear
          cmt
        end

        # Re-generate record list
        def refresh # returns self
          (___file_keys - list.keys).each do |key|
            push(jload(__rec_fname(key)))
          end
          verbose { 'Initiate Record Archive done' }
          cmt
        end

        def refresh_bg # returns self
          Threadx::Fork.new('RecArc(rec_list)', 'mcr', @id) do
            refresh
          end
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
    end

    puts RecArc.new.ext_local.clear.refresh if __FILE__ == $PROGRAM_NAME
  end
end
