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
            @frame = { changed: nil }
            @sel = Select.new(@cfg[:dbi], :command).get(ent.id)
            @cfg[:nocache] = @sel[:nocache] if @sel.key?(:nocache)
            ___init_body(ent)
            # For send back
            @stat.echo = ent[:frame] = @frame[:struct]
            verbose { "Frame Status  #{@frame.inspect}" }
            ent
          end

          def ___init_body(ent)
            @sel[:body] = ent.deep_subst(@cfg[:body]) || return
            verbose { "Body:#{@cfg[:label]}(#{@id})" }
            @sp = type?(@cfg[:stream], Hash)
            @codec = Codec.new(@sp[:endian])
            @frame[:struct] = __mk_frame(@sel[:struct])
            ___chk_nocache
            verbose { "Cmd Generated [#{@id}]" }
          end

          def ___chk_nocache
            return if @cfg[:nocache] || !@frame[:changed]
            warning("Cache stored (#{@id}) despite Frame includes Status")
            @cfg[:nocache] = true
          end

          # instance var frame,sel,field,fstr
          def __mk_frame(array)
            array.map do |dbc|
              p dbc
              dbc.is_a?(Array) ? ___mk_cc(dbc) : ___single_frame(dbc)
            end.join
          end

          def ___mk_cc(array)
            @frame[:cc] = CheckCode.new(@sp[:ccmethod]) do |ccr|
              array.map { |dbc| ___single_frame(dbc, ccr) }.join
            end
          end

          def ___single_frame(dbc, ccr = nil)
            word = ___conv_by_cc(dbc[:val].dup)
            word = ___conv_by_stat(word)
            ___set_csv_frame(word, dbc, ccr)
          end

          def ___conv_by_cc(word)
            return word unless @frame.key?(:cc)
            @frame[:cc].subst(word)
            word
          end

          def ___conv_by_stat(word)
            res = @stat.subst(word)
            if res != word
              @frame[:changed] = true
              verbose { cformat('Convert (%s) %S -> %S', @id, word, res) }
            end
            res
          end

          def ___set_csv_frame(str, db, ccr = nil)
            # Allow csv parameter
            str.split(',').map { |s| __mk_code(s, db, ccr) }.join
          end

          def __mk_code(str, db = {}, ccr = nil)
            return '' unless str
            verbose { "Add [#{str.inspect}]" }
            code = @codec.encode(str, db)
            ccr << code if ccr
            code
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
