#!/usr/bin/ruby
require 'libmcrseq'
require 'libparam'
# CIAX-XML
module CIAX
  # Macro Layer
  module Mcr
    # Sequencer List which provides sequencer list as a server
    # @cfg[:db] associated site/layer should be set
    class List < Hashx
      attr_reader :records, :threads
      def initialize(par, records = Records.new)
        super()
        @par = type?(par, Parameter)
        @records = type?(records, Records)
        @threads = ThreadGroup.new
      end

      def interrupt
        @threads.list.each { |th| th.raise(Interrupt) }
        self
      end

      def reply(cid)
        cmd, id=cid.split(':')
        sequences.each do |seq|
          next if seq.id != id
          return seq.reply(cmd)
        end
        nil
      end

      # pid is Parent ID (user=0,mcr_id,etc.) which is source of command issued
      def add(ent, pid = '0')
        seq = Seq.new(ent, pid) { |e, p| add(e, p) }
        @threads.add(seq.fork) # start immediately
        @records[seq.id] = seq.record
        put(seq.id, seq)
        @par.add(seq.id)
        seq
      end

      def alives
        @threads.list.map { |th| th[:id] }.compact
      end

      def sequences
        @threads.list.map { |th| th[:obj] }.compact
      end

      def alive?(id)
        alives.include?(id)
      end

      def clean
        (keys - alives).each do |id|
          delete(id)
          @records.delete(id)
        end
        @par.clean(alives)
        self
      end
    end

    class Records < Hashx
      def ext_http(host)
        @host = host
        self
      end

      def upd
        values.each{|rec| rec.upd }
        self
      end

      def get(id)
        return self[id] if self[id]
        self[id] = Record.new(id).ext_http(@host)
      end
    end
  end
end
