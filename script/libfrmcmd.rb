#!/usr/bin/ruby
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
          def initialize(super_cfg, atrb = Hashx.new)
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
            @fstr = {}
            @sel = ___init_sel
            @cfg[:nocache] = @sel[:nocache] if @sel.key?(:nocache)
            @chg_flg = nil
            @frame = ___init_frame
            @sel[:body] = ent.deep_subst(@cfg[:body])
            ___init_body(ent) if @sel[:body]
            ent
          end

          def ___init_body(ent)
            verbose { "Body:#{@cfg[:label]}(#{@id})" }
            __add_frame(:body)
            ___init_cc
            __add_frame(:main)
            ___chk_nocache
            verbose { "Cmd Generated [#{@id}]" }
            # For send back
            @field.echo = ent[:frame] = @fstr[:main]
            ent
          end

          def ___init_sel
            if /true|1/ =~ @cfg[:noaffix]
              { main: [:body] }
            else
              Hashx.new(@cfg[:dbi].get(:command)[:frame])
            end
          end

          def ___init_frame
            sp = type?(@cfg[:stream], Hash)
            Frame.new(sp[:endian], sp[:ccmethod])
          end

          def ___init_cc
            return unless @sel.key?(:ccrange)
            @frame.cc.enclose { __add_frame(:ccrange) }
          end

          def ___chk_nocache
            return if @cfg[:nocache] || !@chg_flg
            warning("Cache stored (#{@id}) despite Frame includes Status")
            @cfg[:nocache] = true
          end

          # instance var frame,sel,field,fstr
          def __add_frame(domain)
            @frame.reset
            @sel[domain].each { |db| ___frame_by_type(db) }
            @fstr[domain] = @frame.copy
          end

          def ___frame_by_type(db)
            if db.is_a? Hash
              subfrm = ___conv_by_stat(___conv_by_cc(db[:val]))
              ___set_csv_frame(subfrm, db)
            else # ccrange,body ...
              @frame.push(@fstr[db.to_sym])
            end
          end

          def ___conv_by_cc(val)
            val.gsub(/\$\{cc\}/) { @frame.cc }
          end

          def ___conv_by_stat(frame)
            subfrm = @field.subst(frame)
            if subfrm != frame
              @chg_flg = true
              verbose do
                "Convert (#{@id}) #{frame.inspect} -> #{subfrm.inspect}"
              end
            end
            subfrm
          end

          def ___set_csv_frame(subfrm, db)
            # Allow csv parameter
            subfrm.split(',').each do |s|
              @frame.push(s, db)
            end
          end
        end
      end
    end

    if __FILE__ == $PROGRAM_NAME
      require 'libfieldconv'
      require 'libfrmdb'
      cap = '[dev] [cmd] (par) < field_file'
      ConfOpts.new(cap, options: 'r') do |cfg, args, opt|
        fld = cfg[:field] = Field.new(args.shift)
        # dbi.pick alreay includes :layer, :command, :version
        cobj = Index.new(cfg, fld.dbi.pick(%i(stream)))
        rem = cobj.add_rem.def_proc { |ent| ent.msg = ent[:frame] }.add_ext
        fld.jmerge unless STDIN.tty?
        res = rem.set_cmd(args).exe_cmd('test')
        if opt[:r]
          print res.msg
        else
          puts res.path
        end
      end
    end
  end
end
