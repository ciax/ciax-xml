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
            _init_form_int
            add_form('flush', 'Stream')
            @disp_dic['set'] = '[key(@idx)] [val(,val)]'
          end
        end
      end
      # External Command Group
      module Ext
        # Generate [:frame]
        class Form
          private

          # Substitution order
          #  1. Parameter($1,$2..)
          #  2. Status   (${id1}, ${id2}..)

          def _gen_entity(opt)
            ent = super
            @stat = type?(@cfg[:stat], Field)
            @sel = Select.new(@cfg[:dbi], :command).get(ent[:id])
            @cfg[:nocache] = @sel[:nocache] if @sel.key?(:nocache)
            @stat.echo = ___init_frame(ent)
            ent
          end

          def ___init_frame(ent)
            verbose { "Body:#{@cfg[:label]}(#{@id})" }
            @sp = type?(@cfg[:dbi][:stream], Hash)
            @codec = Codec.new(@sp[:endian])
            @frame = ['']
            ent[:frame] = ___mk_frame(ent.deep_subst_par(@sel[:struct]))
          end

          # instance var frame,sel,field,fstr
          def ___mk_frame(array)
            array.each do |dbc|
              dbc.is_a?(Array) ? ___cc_frame(dbc) : __single_frame(dbc)
            end
            # Replace check code with ${cc}
            @frame.map do |v|
              v.is_a?(String) ? v : __mk_code(@cc.ccc, v)
            end.join
          end

          def ___cc_frame(array)
            verbose { cfmt('CC Start %p', array) }
            @frame.push('')
            array.map { |dbc| __single_frame(dbc) }.join
            @cc = CheckCode.new(@sp[:ccmethod]) { @frame.last }
            verbose { cfmt('CC End %p', @cc) }
          end

          def __single_frame(dbc)
            word = ___chk_cc(dbc)
            return('') unless word
            # Replace status with ${status_id}
            res = @stat.subst(word)
            # No cache if status replacement
            chg = @cfg[:nocache] = true if res != word
            verbose { cfmt('Convert (%s) %p -> %p', @id, word, res) } if chg
            # Allow csv parameter
            code = res.split(',').map { |s| __mk_code(s, dbc) }.join
            verbose { cfmt('Cmd Frame Db [%p] -> %p', dbc, code) }
            @frame.last << code
          end

          def ___chk_cc(dbc)
            if dbc[:type] == 'cc'
              @frame.push(dbc)
              @frame.push('')
              return
            end
            dbc[:val].dup
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
      Opt::Conf.new(cap, options: 'rf') do |cfg|
        if cfg.opt[:f]
          dbi = Db.new.get(cfg.args.shift)
          cfg[:stat] = Field.new(dbi)
        else
          dbi = (cfg[:stat] = Field.new(cfg.args)).dbi
        end
        # dbi.pick alreay includes :layer, :command, :version
        cobj = Index.new(cfg, dbi.pick(:stream))
        rem = cobj.add_rem.def_proc { |ent| ent.msg = ent[:frame] }
        rem.add_ext
        rem.add_int
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
