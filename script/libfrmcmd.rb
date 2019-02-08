#!/usr/bin/env ruby
require 'libcmdext'
require 'libframe'
require 'libfield'
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
            @field = type?(@cfg[:field], Field)
            @fstr = { changed: nil }
            @frame = ''
            ___init_sel(ent)
            ___init_body
            # For send back
            @field.echo = ent[:frame] = @fstr[:main]
            verbose { "Frame Status  #{@fstr.inspect}" }
            ent
          end

          def ___init_body
            return unless @sel[:body]
            verbose { "Body:#{@cfg[:label]}(#{@id})" }
            sp = type?(@cfg[:stream], Hash)
            @codec = Codec.new(sp[:endian])
            __mk_frame(:body)
            ___mk_cc(sp[:ccmethod])
            __mk_frame(:main)
            ___chk_nocache
            verbose { "Cmd Generated [#{@id}]" }
          end

          def ___init_sel(ent)
            @sel = if /true|1/ =~ @cfg[:noaffix]
                     { main: [:body] }
                   else
                     Hashx.new(@cfg[:dbi].get(:command)[:frame])
                   end
            @cfg[:nocache] = @sel[:nocache] if @sel.key?(:nocache)
            @sel[:body] = ent.deep_subst(@cfg[:body])
          end

          def ___mk_cc(method)
            return unless @sel.key?(:ccrange)
            @fstr[:cc] = CheckCode.new(method) do |ccr|
              __mk_frame(:ccrange, ccr)
            end.ccc
          end

          def ___chk_nocache
            return if @cfg[:nocache] || !@fstr[:changed]
            warning("Cache stored (#{@id}) despite Frame includes Status")
            @cfg[:nocache] = true
          end

          # instance var frame,sel,field,fstr
          def __mk_frame(domain, ccr = nil)
            @frame = ''
            @sel[domain].each { |db| ___frame_by_type(db, ccr) }
            @fstr[domain] = @frame
          end

          def ___frame_by_type(db, ccr = nil)
            if db.is_a? Hash
              word = ___conv_by_cc(db[:val].dup)
              word = ___conv_by_stat(word)
              ___set_csv_frame(word, db, ccr)
            else # cunk data: ccrange,body ...
              __frame_push(@fstr[db.to_sym], {}, ccr)
            end
          end

          def __frame_push(str, db = {}, ccr = nil)
            return unless str
            code = @codec.encode(str, db)
            @frame << code
            ccr << code if ccr
            verbose { "Add [#{str.inspect}]" }
          end

          def ___conv_by_cc(word)
            return word unless @fstr.key?(:cc)
            word.gsub(/\$\{cc\}/) { @fstr[:cc] }
          end

          def ___conv_by_stat(word)
            res = @field.subst(word)
            if res != word
              @fstr[:changed] = true
              verbose do
                "Convert (#{@id}) #{word.inspect} -> #{res.inspect}"
              end
            end
            res
          end

          def ___set_csv_frame(str, db, ccr = nil)
            # Allow csv parameter
            str.split(',').each do |s|
              __frame_push(s, db, ccr)
            end
          end
        end
      end
    end

    if __FILE__ == $PROGRAM_NAME
      require 'libfieldconv'
      require 'libfrmdb'
      cap = '[dev] [cmd] (par) < field_file'
      ConfOpts.new(cap, options: 'r') do |cfg|
        fld = cfg[:field] = Field.new(cfg.args.shift)
        # dbi.pick alreay includes :layer, :command, :version
        cobj = Index.new(cfg, fld.dbi.pick(%i(stream)))
        rem = cobj.add_rem.def_proc { |ent| ent.msg = ent[:frame] }.add_ext
        fld.jmerge unless STDIN.tty?
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
