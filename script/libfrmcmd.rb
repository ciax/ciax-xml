#!/usr/bin/ruby
require 'libremote'
require 'libframe'
require 'libfield'

module CIAX
  # Frame Layer
  module Frm
    include Remote
    # cfg should have [:field]
    module Int
      # Internal Command Group
      class Group < Remote::Int::Group
        def initialize(cfg, attr = {})
          super
          add_item('save', '[key,key...] [tag]', def_pars(2))
          add_item('load', '[tag]', def_pars(1))
          add_item('set', '[key(:idx)] [val(,val)]', def_pars(2))
          add_item('flush', 'Stream')
        end
      end
    end
    # External Command Group
    module Ext
      include Remote::Ext
      class Group < Ext::Group; end
      class Item < Ext::Item
        def gen_entity(opt)
          ent = super
          @field = type?(@cfg[:field], Field)
          @fstr = {}
          @sel = _init_sel
          @chg_flg = nil
          @frame = _init_frame
          @sel[:body] = ent.deep_subst(@cfg[:body])
          return ent unless @sel[:body]
          verbose { "Body:#{@cfg[:label]}(#{@cfg[:id]})" }
          _add_frame(:body)
          _init_cc
          _add_frame(:main)
          if @chg_flg && !@cfg[:nocache]
            warning('Cache stored despite Frame includes Status')
            @cfg[:nocache] = true
          end
          frame = @fstr[:main]
          verbose { "Cmd Generated [#{@cfg[:id]}]" }
          @field.echo = frame # For send back
          ent[:frame] = frame
          ent
        end

        private

        def _init_sel
          if /true|1/ =~ @cfg[:noaffix]
            { main: [:body] }
          else
            Hash[@cfg[:dbi][:command][:frame]]
          end
        end

        def _init_frame
          sp = @cfg[:dbi][:stream]
          Frame.new(sp[:endian], sp[:ccmethod])
        end

        def _init_cc
          if @sel.key?(:ccrange)
            @frame.cc_mark
            _add_frame(:ccrange)
            @frame.cc_set
          end
        end

        # instance var frame,sel,field,fstr
        def _add_frame(domain)
          @frame.reset
          @sel[domain].each do|a|
            case a
            when Hash
              frame = a[:val].gsub(/\$\{cc\}/) { @frame.cc }
              subfrm = @field.subst(frame)
              @chg_flg = true if subfrm != frame
              subfrm.split(',').each do|s|
                @frame.add(s, a)
              end
            else # ccrange,body ...
              @frame.add(@fstr[a.to_sym])
            end
          end
          @fstr[domain] = @frame.copy
        end
      end
    end

    if __FILE__ == $PROGRAM_NAME
      require 'libfrmrsp'
      require 'libfrmdb'
      OPT.parse('r')
      id, *args = ARGV
      ARGV.clear
      begin
        dbi = Db.new.get(id)
        cfg = Config.new
        fld = cfg[:field] = Field.new(dbi)
        cobj = Index.new(cfg, dbi: dbi)
        cobj.add_rem.def_proc { |ent| ent[:frame] }
        cobj.rem.add_ext(Ext)
        fld.read unless STDIN.tty?
        res = cobj.set_cmd(args).exe_cmd('test')
        puts(OPT[:r] ? res : res.inspect)
      rescue InvalidCMD
        OPT.usage("#{id} [cmd] (par) < field_file")
      rescue InvalidID
        OPT.usage('[dev] [cmd] (par) < field_file')
      end
    end
  end
end
