#!/usr/bin/ruby
require 'libseq'
require 'libparam'
require 'libreclist'
# CIAX-XML
module CIAX
  # Macro Layer
  module Mcr
    # List which provides records
    # @threads provides sequencer list as a server
    # @cfg[:db] associated site/layer should be set
    class List < Hashx
      attr_reader :threads
      def initialize
        super()
        # @threads : List of Sequencer
        # self     : List of Record (Current running)
        # @rec_list: List of Record Header (Log)
        @threads = ThreadGroup.new
        @rec_list = RecList.new
      end

      #### Driver Methods ####
      def interrupt
        @threads.list.each { |th| th.raise(Interrupt) }
        self
      end

      def reply(cid)
        cmd, id = cid.split(':')
        @threads.list.each do |th|
          seq = th[:obj] || next
          next if seq.id != id
          return seq.reply(cmd)
        end
        nil
      end

      # pid is Parent ID (user=0,mcr_id,etc.) which is source of command issued
      def add(ent, pid = '0')
        seq = Sequencer.new(ent, pid) { |e, p| add(e, p) }
        @threads.add(type?(seq.fork, Threadx::Fork)) # start immediately
        put(seq.id, seq.record)
        @rec_list.add(seq.record)
        seq
      end

      def alives
        @threads.list.map { |th| th[:obj] }.compact.map do |seq|
          type?(seq, Sequencer).id
        end
      end

      def alive?(id)
        alives.include?(id)
      end

      def clean
        (keys - alives).each do |id|
          delete(id)
        end
        self
      end

      #### Client Methods ####
      def ext_http(host)
        @host = host
        self
      end

      def upd
        values.each(&:upd)
        self
      end

      def get(id)
        type?(id, String)
        super { |key| Record.new(key).ext_http(@host) }
      end
    end
  end
end
