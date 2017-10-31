#!/usr/bin/ruby
require 'libcmdext'
require 'libframe'
require 'libfield'
# CIAX-XML Command module
module CIAX
  Msg.deep_include(Frm, CmdTree)
  # Frame Layer
  module Frm
    # Remote Domain
    module Remote
      # Internal Commands
      module Int
        # Internal Command Group
        class Group
          # cfg should have [:field]
          def initialize(cfg, atrb = Hashx.new)
            super
            init_item_file_io
            add_item('set', '[key(:idx)] [val(,val)]', def_pars(2))
            add_item('flush', 'Stream')
          end
        end
      end
      # External Command Group
      module Ext
        # Generate [:frame]
        class Item
          def gen_entity(opt)
            ent = super
            @field = type?(@cfg[:field], Field)
            @fstr = {}
            @sel = _init_sel
            @cfg[:nocache] = @sel[:nocache] if @sel.key?(:nocache)
            @chg_flg = nil
            @frame = _init_frame
            @sel[:body] = ent.deep_subst(@cfg[:body])
            _init_body(ent) if @sel[:body]
            ent
          end

          private

          def _init_body(ent)
            verbose { "Body:#{@cfg[:label]}(#{@id})" }
            _add_frame(:body)
            _init_cc
            _add_frame(:main)
            _chk_nocache
            verbose { "Cmd Generated [#{@id}]" }
            # For send back
            @field.echo = ent[:frame] = @fstr[:main]
            ent
          end

          def _init_sel
            if /true|1/ =~ @cfg[:noaffix]
              { main: [:body] }
            else
              Hashx.new(@cfg[:command][:frame])
            end
          end

          def _init_frame
            sp = type?(@cfg[:stream], Hash)
            Frame.new(sp[:endian], sp[:ccmethod])
          end

          def _init_cc
            return unless @sel.key?(:ccrange)
            @frame.cc.enclose { _add_frame(:ccrange) }
          end

          def _chk_nocache
            return if @cfg[:nocache] || !@chg_flg
            warning("Cache stored (#{@id}) despite Frame includes Status")
            @cfg[:nocache] = true
          end

          # instance var frame,sel,field,fstr
          def _add_frame(domain)
            @frame.reset
            @sel[domain].each { |db| _frame_by_type(db) }
            @fstr[domain] = @frame.copy
          end

          def _frame_by_type(db)
            if db.is_a? Hash
              subfrm = _conv_by_stat(_conv_by_cc(db[:val]))
              _set_csv_frame(subfrm, db)
            else # ccrange,body ...
              @frame.push(@fstr[db.to_sym])
            end
          end

          def _conv_by_cc(val)
            val.gsub(/\$\{cc\}/) { @frame.cc }
          end

          def _conv_by_stat(frame)
            subfrm = @field.subst(frame)
            if subfrm != frame
              @chg_flg = true
              verbose do
                "Convert (#{@id}) #{frame.inspect} -> #{subfrm.inspect}"
              end
            end
            subfrm
          end

          def _set_csv_frame(subfrm, db)
            # Allow csv parameter
            subfrm.split(',').each do |s|
              @frame.push(s, db)
            end
          end
        end
      end
    end

    if __FILE__ == $PROGRAM_NAME
      require 'libfrmrsp'
      require 'libfrmdb'
      cap = '[dev] [cmd] (par) < field_file'
      ConfOpts.new(cap, options: 'r') do |cfg, args|
        dbi = Db.new.get(args.shift)
        fld = cfg[:field] = Field.new(dbi)
        # dbi.pick alreay includes :layer, :command, :version
        cobj = Index.new(cfg, dbi.pick(%i(stream)))
        cobj.add_rem.def_proc { |ent| ent.msg = ent[:frame] }
        cobj.rem.add_ext
        fld.jmerge unless STDIN.tty?
        res = cobj.set_cmd(args).exe_cmd('test')
        puts(cfg[:opt][:r] ? res.msg : res.path)
      end
    end
  end
end
