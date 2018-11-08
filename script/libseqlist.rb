#!/usr/bin/ruby
require 'libmcrexe'

# CIAX-XML
module CIAX
  # Macro Layer
  module Mcr
    # List which provides Sequencer
    # @cfg[:sv_stat] and [:rec_list] should be set
    class SeqList < ThreadGroup
      attr_reader :threads, :add_proc
      def initialize(cfg, &add_proc)
        super()
        @sv_stat = Msg.type?(cfg[:sv_stat], Prompt)
        @sv_stat.upd_procs << proc do |ss|
          ss.flush(:list, alives).repl(:sid, '')
        end
        @add_proc = add_proc
        # @rec_arc: List of Record Header (Log)
        @rec_arc = Msg.type?(cfg[:rec_arc], RecArc)
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
        exe = Exe.new(ent) { |e| add(e) }
        super(Msg.type?(exe.start.thread, Threadx::Fork)) # start immediately
        seq = exe.seq
        @sv_stat.push(:list, seq.id).repl(:sid, seq.id)
        @rec_arc.push(seq.record)
        @add_proc.call(seq.record) if @add_proc
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
