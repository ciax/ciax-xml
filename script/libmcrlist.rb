#!/usr/bin/ruby
require 'libmcrseq'
# CIAX-XML
module CIAX
  # Macro Layer
  module Mcr
    # Sequencer List which provides sequencer list as a server
    # @cfg[:db] associated site/layer should be set
    class List < Hashx
      def initialize
        super
        @threads = ThreadGroup.new
      end

      def interrupt
        @threads.list.each { |th| th.raise(Interrupt) }
        self
      end

      # pid is Parent ID (user=0,mcr_id,etc.) which is source of command issued
      def add(ent, pid = '0')
        seq = Seq.new(ent, pid){ |e,p| add(e,p) }
        @threads.add(seq.fork) # start immediately
        put(seq.id, seq)
      end

      def clean
        alive = @threads.list.map { |th| th[:id] }.compact
        (keys - alive).each { |id| delete(id) }
        self
      end
    end
  end
end
