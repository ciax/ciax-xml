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

        def add_empty
          @empty = add_grp('Empty')
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
          super("input_#{layer_name}", id)
          _attr_set(ver)
          init_time2cmt
          ext_local.ext_log
        end
      end

      #### Groups ####

      # Accept empty command for upd
      module Empty
        deep_include CmdBase
        # System Command Group
        class Group < CmdBase::Group
          def initialize(dom_cfg, atrb = Hashx.new)
            super
            add_form(nil, nil, def_msg: '')
          end
        end
      end

      # System Commands
      module Sys
        deep_include CmdBase
        # System Command Group
        class Group < CmdBase::Group
          def initialize(dom_cfg, atrb = Hashx.new)
            atrb.get(:caption) { 'System Commands' }
            super
            add_form('interrupt', nil, def_msg: 'INTERRUPT')
            add_form('reset', 'Stream', def_msg: 'RESET')
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

          private

          def _init_form_int
            add_form('set', '[key] [val]').pars_any(2)
            add_form('del', '[key,...]').pars_any(1)
            add_form('save', '[key,key...] [tag]').pars_any(2)
            add_form('load', '[tag]').pars.add_enum([])
          end
        end
      end
    end
  end
end
