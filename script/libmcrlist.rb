#!/usr/bin/ruby
require 'libseq'
require 'libparam'
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
      end

      #### Driver Methods ####
      def interrupt
        @threads.list.each { |th| th.raise(Interrupt) }
        self
      end

      def reply(cid)
        cmd, id = cid.split(':')
        @threads.list.each do |th|
          next if th[:id] != id
          return th[:query].reply(cmd)
        end
        nil
      end

      # pid is Parent ID (user=0,mcr_id,etc.) which is source of command issued
      def add(ent, pid = '0') # returns Sequencer
        seq = Sequencer.new(ent, pid) { |e, p| add(e, p) }
        @threads.add(type?(seq.fork, Threadx::Fork)) # start immediately
        put(seq.id, seq.record)
        seq
      end

      def alives
        @threads.list.map { |th| th[:id] }.compact
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
        super { |key| Record.new(key).ext_http(@host, 'record') }
      end
    end
  end
end