#!/usr/bin/ruby
require 'libremote'
require 'libframe'
require 'libfield'

module CIAX
  module Frm
    include Remote
    # cfg should have [:field]
    module Int
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

    module Ext
      include Remote::Ext
      class Group < Ext::Group; end
      class Item < Ext::Item; end
      class Entity < Ext::Entity
        def initialize(cfg, attr = {})
          super
          @field = type?(self[:field], Field)
          @fstr = {}
          if /true|1/ === self['noaffix']
            @sel = { :main => ['body'] }
          else
            @sel = Hash[self[:dbi][:command][:frame]]
          end
          @frame = Frame.new(self[:dbi]['endian'], self[:dbi]['ccmethod'])
          return unless @body
          @sel[:body] = @body
          verbose { "Body:#{self['label']}(#{@id})" }
          mk_frame(:body)
          if @sel.key?(:ccrange)
            @frame.cc_mark
            mk_frame(:ccrange)
            @frame.cc_set
          end
          mk_frame(:main)
          frame = @fstr[:main]
          verbose { "Cmd Generated [#{@id}]" }
          self[:frame] = frame
          @field.echo = frame # For send back
        end

        private
        # instance var frame,sel,field,fstr
        def mk_frame(domain)
          conv = nil
          @frame.reset
          @sel[domain].each{|a|
            case a
            when Hash
              frame = a['val'].gsub(/\$\{cc\}/) { @frame.cc }
              frame = @field.subst(frame)
              conv = true if frame != a['val']
              frame.split(',').each{|s|
                @frame.add(s, a)
              }
            else # ccrange,body ...
              @frame.add(@fstr[a.to_sym])
            end
          }
          @fstr[domain] = @frame.copy
          conv
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
        fld = cfg[:field] = Field.new.setdbi(dbi)
        cobj = Index.new(cfg, { :dbi => dbi })
        cobj.add_rem.def_proc { |ent| ent[:frame] }
        cobj.rem.add_ext(Ext)
        fld.read unless STDIN.tty?
        res = cobj.set_cmd(args).exe_cmd('test')
        puts(OPT['r'] ? res : res.inspect)
      rescue InvalidCMD
        OPT.usage("#{id} [cmd] (par) < field_file")
      rescue InvalidID
        OPT.usage('[dev] [cmd] (par) < field_file')
      end
    end
  end
end
