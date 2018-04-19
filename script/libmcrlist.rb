#!/usr/bin/ruby
require 'libseq'
# CIAX-XML
module CIAX
  # Macro Layer
  module Mcr
    # List which provides records
    # @threads provides sequencer list as a server
    # @cfg[:db] associated site/layer should be set
    class List < ThreadGroup
      attr_reader :threads
      def initialize(rec_list)
        super()
        # @rec_list: List of Record Header (Log)
        @rec_list = rec_list
      end

      #### Driver Methods ####
      def interrupt
        list.each { |th| th.raise(Interrupt) }
        self
      end

      def reply(cid)
        cmd, id = cid.split(':')
        list.each do |th|
          next if th[:id] != id
          return th[:query].reply(cmd)
        end
        nil
      end

      # pid is Parent ID (user=0,mcr_id,etc.) which is source of command issued
      def add(ent, pid = '0') # returns Sequencer
        seq = Sequencer.new(ent, pid) { |e, p| super(e, p) }
        super(Msg.type?(seq.fork, Threadx::Fork)) # start immediately
        @rec_list.push(seq.record)
        seq
      end

      def alives
        list.map { |th| th[:id] }.compact
      end

      def alive?(id)
        alives.include?(id)
      end

      def clean
        act = @rec_list.active
        (act.keys - alives).each do |id|
          act.delete(id)
        end
        self
      end
    end
  end
end
