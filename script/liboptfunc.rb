#!/usr/bin/env ruby
# CIAX-XML
module CIAX
  module Opt
    # Option Functions
    module Func
      # Mode (Device) [prompt]
      # none     : test all layers            [test]
      # -e       : run all sites/layers       [drv]
      # -p       : run default sites/layers   [drv]
      # -c       : to default host all layers [cl]
      # -h[host] : to host all layers
      # -l[layer]: to localhost lower layers
      # -s       : server

      # Mode (Macro)
      # none : test
      # -d   : dryrun (get status only)
      # -e   : with device driver
      # -c   : client to macro server
      # -p   : partialy client to device server
      # -s   : server

      # Check first
      def cl?
        __any_key?(:c) || (host && !key?(:l))
      end

      def drv?
        __any_key?(:e, :l, :d, :p)
      end

      def test?
        !cl? && !drv?
      end

      def sv?
        key?(:s) && true
      end

      def bg?
        key?(:b) && true
      end

      # For macro
      # dry run mode
      def dry?
        key?(:d) && true
      end

      def nonstop?
        key?(:n) && true
      end

      def mcr_log?
        drv? && !dry?
      end

      # Server run for git-tag
      def git_tag?
        mcr_log? && bg?
      end

      # Distributes connection to the proper sites
      def proper?
        key?(:p)
      end

      # tf = site is member of run_list?
      def site_opt(tf)
        return dup unless proper?
        hash = dup.update(tf ? :e : :c => true)
        hash.delete(:p)
        hash
      end

      def top_layer
        @valids = []
        %i(f a w x m).any? do |l|
          @valids.unshift(l)
          key?(l)
        end || @valids = %i(w a f)
        @optdb.layers[@valids.shift]
      end

      # Others
      def sub_opt
        return dup unless (lo = self[:l])
        @valids.shift
        return dup if @valids.include?(lo.to_sym)
        sb = %i(s e l).each_with_object(dup) { |k, o| o.delete(k) }
        sb.update(h: 'localhost')
      end

      def host
        self[:h]
      end
    end

    # Option DB Setting
    class Db < Hash
      attr_reader :layers
      def initialize(optarg)
        optarg.each do |k, v|
          self[k] = { title: v } if k.to_s.length == 1
        end
        # Custom options
        optarg[:options] = optarg[:options].to_s + keys.join
        ___mk_optdb
      end

      def get(id)
        self[id][:title] if key?(id)
      end

      private

      # Remained Options
      # g,i,k,m,o,q,t,u,y,z
      def ___mk_optdb
        ___optdb_client
        ___optdb_system
        ___optdb_view
        ___optdb_cui
        ___optdb_layer
        ___optdb_mcr
        ___optdb_dev
      end

      ## Common in Macro and Device
      # Client option
      def ___optdb_client
        db = { c: 'default', l: '[layer] lower', h: '[host]' }
        __add_optdb(db, 'client to %s')
      end

      # System mode
      def ___optdb_system
        db = { s: 'server', b: 'back ground', e: 'execution', p: 'proper' }
        __add_optdb(db, '%s mode')
      end

      # For data appearance
      def ___optdb_view
        db = { r: 'raw', j: 'json', v: 'csv' }
        __add_optdb(db, '%s data output')
      end

      # For input interface (Shell or Command Line)
      def ___optdb_cui
        db = { i: 'interactive' }
        __add_optdb(db, '%s mode')
      end

      ## For Macro
      def ___optdb_mcr
        db = { d: 'dryrun', n: 'non-stop' }
        __add_optdb(db, '%s mode')
      end

      ## For Device
      def ___optdb_dev
        db = { t: '[key=val,..]' }
        __add_optdb(db, 'test conditions %s')
      end

      # Layer option
      def ___optdb_layer
        @layers = { w: 'wat', f: 'frm', x: 'hex', a: 'app' }
        __add_optdb(@layers, '%s layer')
      end

      def __add_optdb(db, fmt)
        db.each do |k, v|
          self[k] = { title: format(fmt, v) } unless key?(k)
        end
      end
    end
  end
end
