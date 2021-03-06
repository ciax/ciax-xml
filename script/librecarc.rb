#!/usr/bin/env ruby
require 'librecord'
require 'libthreadx'
module CIAX
  # Macro Layer
  module Mcr
    # Record Archive Dic (Dir)
    #   Index of Records
    class RecArc < Varx
      attr_reader :push_procs
      def initialize
        super('list', 'record')
        @push_procs = [proc { verbose { 'Propagate push' } }]
        # [:dic] : Archive Dic : Dictionary of Record (id: cid,pid,res)
        self[:format_ver] = 1
      end

      def dic
        self[:dic] ||= {}
      end

      def get(id)
        self[:dic][id] || id_err(id, 'Record Archive')
      end

      def list
        dic.keys.sort
      end

      def tail(num = 1)
        upd
        list.uniq.last(num.to_i)
      end

      # Mode
      #   Skelton
      #   Remote (Read only)
      #   Local (Read/Write Memory, File read only)
      #   Local_Save (Read/Write File)
      # Macro Response Module
      module Local
        include Varx::Local
        def self.extended(obj)
          Msg.type?(obj, RecArc)
        end

        def ext_local
          super
          init_time2cmt
        end

        def push(record) # returns self
          return self unless record.is_a?(Hash) && record[:id].to_i > 0
          __push_record(record)
          @push_procs.each { |p| p.call(record) }
          cmt
        end

        # For format changes
        def clear
          dic.clear
          cmt
        end

        # Re-generate record dic
        def refresh # returns self
          (___file_keys - dic.keys).each do |key|
            __push_record(jload(__rec_fname(key)))
          end
          verbose { 'Initiate Record Archive refresh done' }
          cmt
        end

        private

        def __push_record(record)
          return unless __extract(record) == 'busy' && record.is_a?(Record)
          record.finish_procs << proc { |r| __extract(r) && cmt }
        end

        def __extract(rec)
          ele = Hashx.new(rec).pick(:cid, :pid, :result) # extract header
          return if ele.empty?
          verbose { 'Record Archive Updated' }
          dic[rec[:id]] = ele
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

    if __FILE__ == $PROGRAM_NAME
      Opt::Get.new('', options: 'ch') do |opts|
        puts RecArc.new.cmode(opts.host)
      end
    end
  end
end
