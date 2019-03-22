#!/usr/bin/env ruby
require 'libvarx'
require 'libcmdlocal'
module CIAX
  module CmdTree
    # Command Index
    class Index < Local::Index
      attr_reader :rem
      def add_rem(obj = nil, atrb = Hashx.new) # returns Domain
        @rem = obj ? add(obj, atrb) : add_dom('Remote', atrb)
      end
    end
    # Remote Command Domain
    module Remote
      include CmdBase
      # Instance var is @rem in Index
      # @cfg should have [:dbi]
      class Domain < Domain
        attr_reader :sys, :ext, :int
        def initialize(spcfg, atrb = Hashx.new)
          super
          @cfg[:def_proc] = proc {} # proc is re-defined
        end

        def add_sys # returns Group
          @sys = add_grp('Sys')
        end

        def add_ext # returns Group
          @ext = add_grp('Ext')
        end

        def add_int # returns Group
          @int = add_grp('Int')
        end

        def ext_input_log
          # site_id: App, Frm
          # id : Mcr
          @id = @cfg[:site_id] || @cfg[:id]
          verbose { 'Initiate input logging' }
          @cfg[:input] = context_module('Input').new(@id, @cfg[:version])
          self
        end
      end

      # Command Input Logging
      class Input < Varx
        def initialize(id, ver)
          super("input_#{layer_name}")
          _attr_set(id, ver)
          init_time2cmt
          ext_local_log
        end
      end

      #### Groups ####
      # System Commands
      module Sys
        deep_include CmdBase
        # System Command Group
        class Group < CmdBase::Group
          def initialize(dom_cfg, atrb = Hashx.new)
            atrb.get(:caption) { 'System Commands' }
            super
            add_item('interrupt', nil, def_msg: 'INTERRUPT')
            add_item('reset', 'stream', dev_msg: 'RESET')
          end

          def add_empty
            # Accept empty command for upd
            add_item(nil, nil, def_msg: '')
          end
        end
      end

      # Internal Commands
      module Int
        deep_include CmdBase
        # Internal Command Group
        class Group < CmdBase::Group
          def initialize(dom_cfg, atrb = Hashx.new)
            atrb.get(:caption) { 'Internal Commands' }
            super
            @cfg[:nocache] = true
          end

          def init_item_file_io
            add_item('save', '[key,key...] [tag]').pars_any(2)
            add_item('load', '[tag]').pars.add_enum([])
          end
        end
      end
    end
  end
end
