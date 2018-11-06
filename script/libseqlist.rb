#!/usr/bin/ruby
require 'libseq'

# CIAX-XML
module CIAX
  # Macro Layer
  module Mcr
    # List which provides records
    # @threads provides sequencer list as a server
    # @cfg[:db] associated site/layer should be set
    class SeqList < ThreadGroup
      attr_reader :threads
      def initialize(sv_stat, rec_arc)
        super()
        # @rec_arc: List of Record Header (Log)
        @sv_stat = Msg.type?(sv_stat, Prompt)
        @sv_stat.upd_procs << proc do |ss|
          ss.flush(:list, alives).repl(:sid, '')
        end
        @rec_arc = Msg.type?(rec_arc, RecArc)
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
      def add(ent) # returns Sequencer
        seq = Sequencer.new(ent) { |e| add(e) }
        super(Msg.type?(seq.fork, Threadx::Fork)) # start immediately
        @sv_stat.push(:list, seq.id).repl(:sid, seq.id)
        @rec_arc.push(seq.record)
        seq
      end

      def alives
        list.map { |th| th[:id] }.compact
      end

      def alive?(id)
        alives.include?(id)
      end
    end
  end
end
