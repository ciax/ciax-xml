#!/usr/bin/ruby
require 'libmcrseq'
require 'libparam'
# CIAX-XML
module CIAX
  # Macro Layer
  module Mcr
    # Record List which provides sequencer list as a server
    # @cfg[:db] associated site/layer should be set
    class List < Hashx
      attr_reader :records, :threads
      def initialize(par)
        super()
        @par = type?(par, Parameter)
        @threads = ThreadGroup.new
      end

      def interrupt
        @threads.list.each { |th| th.raise(Interrupt) }
        self
      end

      def reply(cid)
        cmd, id=cid.split(':')
        @threads.list.each do |th|
          seq = th[:obj]
          next if seq.id != id
          return seq.reply(cmd)
        end
        nil
      end

      # pid is Parent ID (user=0,mcr_id,etc.) which is source of command issued
      def add(ent, pid = '0')
        seq = Seq.new(ent, pid) { |e, p| add(e, p) }
        @threads.add(seq.fork) # start immediately
        put(seq.id, seq.record)
        @par.add(seq.id)
        seq
      end

      def alives
        @threads.list.map { |th| th[:obj].id }.compact
      end

      def alive?(id)
        alives.include?(id)
      end

      def clean
        (keys - alives).each do |id|
          delete(id)
        end
        @par.clean(alives)
        self
      end

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
