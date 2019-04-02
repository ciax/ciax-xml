#!/usr/bin/env ruby
require 'libcmdext'
require 'libfrmsel'
require 'libfrmstat'
# CIAX-XML Command module
module CIAX
  # Frame Layer
  module Frm
    deep_include(CmdTree)
    # Remote Domain
    module Remote
      # Internal Commands
      module Int
        # Internal Command Group
        class Group
          # cfg should have [:field]
          def initialize(spcfg, atrb = Hashx.new)
            super
            init_item_file_io
            add_item('set', '[key(@idx)] [val(,val)]').pars_any(2)
            add_item('flush', 'Stream')
          end
        end
      end
      # External Command Group
      module Ext
        # Generate [:frame]
        class Item
          private

          def _gen_entity(opt)
            ent = super
            @stat = type?(@cfg[:field], Field)
            @sel = Select.new(@cfg[:dbi], :command).get(ent[:id])
            @cfg[:nocache] = @sel[:nocache] if @sel.key?(:nocache)
            @stat.echo = ___init_frame(ent)
            ent
          end

          def ___init_frame(ent)
            verbose { "Body:#{@cfg[:label]}(#{@id})" }
            @sp = type?(@cfg[:stream], Hash)
            @codec = Codec.new(@sp[:endian])
            ent[:frame] = ent.deep_subst(__mk_frame(@sel[:struct]))
          end

          # instance var frame,sel,field,fstr
          def __mk_frame(array)
            array.map do |dbc|
              dbc.is_a?(Array) ? ___cc_frame(dbc) : ___single_frame(dbc)
            end.join
          end

          def ___cc_frame(array)
            CheckCode.new(@sp[:ccmethod]) do |cc|
              array.map { |dbc| ___single_frame(dbc, cc) }.join
            end
          end

          def ___single_frame(dbc, cc = nil)
            word = dbc[:val].dup
            # Replace check code with ${cc}
            word = cc.subst(word) if cc
            # Replace status with ${status_id}
            res = @stat.subst(word)
            # No cache if status replacement
            chg = @cfg[:nocache] = true if res != word
            verbose { cformat('Convert (%s) %S -> %S', @id, word, res) } if chg
            # Allow csv parameter
            code = res.split(',').map { |s| __mk_code(s, dbc) }.join
            verbose { cformat('Cmd Frame Db [%S] -> %S', dbc, code) }
            code
          end

          def __mk_code(str, db = {})
            return '' unless str
            verbose { "Add [#{str.inspect}]" }
            @codec.encode(str, db)
          end
        end
      end
    end

    if __FILE__ == $PROGRAM_NAME
      require 'libfrmconv'
      require 'libdevdb'
      cap = '[dev] [cmd] (par) < field_file'
      ConfOpts.new(cap, options: 'r') do |cfg|
        if STDIN.tty?
          dbi = Dev::Db.new.get(cfg.args.shift)
          cfg[:field] = Field.new(dbi[:id])
        else
          dbi = (cfg[:field] = Field.new).dbi
        end
        # dbi.pick alreay includes :layer, :command, :version
        cobj = Index.new(cfg, dbi.pick(%i(stream)))
        rem = cobj.add_rem.def_proc { |ent| ent.msg = ent[:frame] }.add_ext
        res = rem.set_cmd(cfg.args).exe_cmd('test')
        if cfg.opt[:r]
          print res.msg
        else
          puts res.path
        end
      end
    end
  end
end
