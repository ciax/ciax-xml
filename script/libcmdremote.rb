#!/usr/bin/ruby
require 'libvarx'
require 'libcmdlocal'
require 'libparam'
module CIAX
  module Cmd
    # Remote Command Domain
    module Remote
      # Instance var is @rem in Index
      class Index < Local::Index
        attr_reader :rem
        def add_rem(obj = Domain)
          @rem = add(obj)
        end
      end

      # @cfg should have [:dbi]
      class Domain < GrpAry
        attr_reader :sys, :ext, :int
        def initialize(cfg, atrb = Hashx.new)
          super
          @cfg[:def_proc] = proc {} # proc is re-defined
        end

        def add_sys(ns = Sys)
          @sys = add(ns::Group)
        end

        def add_ext(ns = Ext)
          @ext = add(ns::Group)
        end

        def add_int(ns = Int)
          @int = add(ns::Group)
        end

        def ext_log(tag = nil)
          id = @cfg[:site_id] || @cfg[:layer_type]
          @cfg[:input] = Input.new(tag, id)
          self
        end
      end

      # Command Input Logging
      class Input < Varx
        def initialize(tag, id)
          super("input_#{tag}", id)
          ext_file
          ext_log
        end
      end

      # For input logging (returns String)
      class Entity < Entity
        def exe_cmd(src, pri = 1)
          if self[:input]
            self[:input].update(cmd: self[:cid], src: src, pri: pri).upd
          end
          super
        end
      end

      #### Groups ####
      module Sys
        # System Command Group
        class Group < Group
          def initialize(dom_cfg, atrb = Hashx.new)
            atrb.get(:caption) { 'System Commands' }
            super
            add_item('interrupt',nil,def_msg: 'INTERRUPT')
            # Accept empty command
            add_item(nil)
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

          def add_file_io
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
