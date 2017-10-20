#!/usr/bin/ruby
require 'libvarx'
require 'libcmdlocal'
require 'libparam'
module CIAX
  module Cmd
    # Command Index (Override)
    class Index
      attr_reader :rem
      def add_rem(obj = nil, atrb = Hashx.new) # returns Domain
        @rem = add(obj || Remote::Domain, atrb)
      end
    end
    # Remote Command Domain
    module Remote
      # Instance var is @rem in Index
      # @cfg should have [:dbi]
      class Domain < GrpAry
        attr_reader :sys, :ext, :int
        def initialize(cfg, atrb = Hashx.new)
          super
          @cfg[:def_proc] = proc {} # proc is re-defined
        end

        def add_sys(ns = Sys) # returns Group
          @sys = add(ns::Group)
        end

        def add_ext(ns = Ext) # returns Group
          @ext = add(ns::Group)
        end

        def add_int(ns = Int) # returns Group
          @int = add(ns::Group)
        end

        def ext_input_log(layer = nil)
          # site_id: App, Frm
          # id : Mcr
          @id = @cfg[:site_id] || @cfg[:id]
          verbose { "Initiate logging input #{layer}" }
          @cfg[:input] = Input.new(layer, @id, @cfg[:version])
          self
        end
      end

      # Command Input Logging
      class Input < Varx
        def initialize(layer, id, ver)
          super("input_#{layer}", id, ver)
          @layer = layer
          init_time2cmt
          ext_local_file
          ext_local_log
        end
      end

      #### Groups ####
      module Sys
        # System Command Group
        class Group < Group
          def initialize(dom_cfg, atrb = Hashx.new)
            atrb.get(:caption) { 'System Commands' }
            super
            add_item('interrupt', nil, def_msg: 'INTERRUPT')
            # Accept empty command except for command line mode
            dom_cfg[:cmd_line_mode] || add_item(nil, nil, def_msg: '')
          end
        end
      end

      module Int
        # Internal Command Group
        class Group < Group
          def initialize(dom_cfg, atrb = Hashx.new)
            atrb.get(:caption) { 'Internal Commands' }
            super
            @cfg[:nocache] = true
          end

          def init_item_file_io
            add_item('save', '[key,key...] [tag]', def_pars(2))
            add_item('load', '[tag]', def_pars(1))
          end

          def def_pars(n = 1)
            ary = []
            n.times { ary << Parameter.new }
            { parameters: ary }
          end
        end
        class Item < Item; end
        class Entity < Entity; end
      end
    end
  end
end
