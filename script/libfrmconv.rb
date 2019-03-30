#!/usr/bin/env ruby
require 'libfrmstat'
require 'libfrmcut'

# Conv Methods
# Input  : upd block(frame,time)
# Output : Field
module CIAX
  # Frame Layer
  module Frm
    # Field class
    class Field
      def ext_local_conv
        extend(Conv).ext_local_conv
      end

      # Frame Response module
      module Conv
        # @< (base),(prefix)
        # @ cobj,sel,fds,frame,fary,cc
        def self.extended(obj)
          Msg.type?(obj, Field)
        end

        # Ent is needed which includes response_id and cmd_parameters
        def ext_local_conv
          type?(@dbi, Dbi)
          @fdbr = @dbi[:response]
          @fds = @fdbr[:index]
          self
        end

        # Convert with corresponding cmd
        def conv(ent)
          frm = @frame.get(ent.id)
          return self unless frm
          ___make_sel(ent)
          # CutFrame structure:
          #   main(total){ ccrange{ body(selected str) } }
          # terminator: frame pointer will jump to terminator
          #   when no length or delimiter is specified
          @rspfrm = CutFrame.new(frm.dup, @dbi[:stream])
          ___make_data
          verbose { 'Conversion Frame -> Field' }
          self
        end

        private

        # @sel structure:
        #   { terminator, :main{}, ccrange{}, :body{} <- changes on every upd }
        def ___make_sel(ent)
          rid = ent[:response]
          idx = @fds[rid] || Msg.cfg_err("No such response id [#{rid}]")
          # SelDB of template
          @sel = Hash[@fdbr[:frame]]
          # SelDB specific for rid
          @sel.update(idx)
          # SelDB applied with Entity (set par)
          @sel[:body] = ent.deep_subst(@sel[:body])
        end

        def ___make_data
          @cache = _dic.deep_copy
          if @sel.key?(:noaffix)
            __getfield_rec(['body'])
          else
            __getfield_rec(@sel[:main])
            @rspfrm.cc_check(@cache.delete('cc'))
          end
          _dic.replace(@cache)
        end

        # Process Frame to Field
        def __getfield_rec(e0, common = {})
          e0.each do |e1|
            ___getfield(e1, common)
          end
        end

        def ___getfield_cc(cc)
          @rspfrm.cc_start
          __getfield_rec(cc)
          @rspfrm.cc_reset
        end

        def ___getfield(e1, common = {})
          case e1[:type]
          when 'field', 'array'
            ___frame_to_field(e1) { @rspfrm.cut(e1.update(common)) }
          when 'ccrange'
            ___getfield_cc(@sel[:ccrange])
          when 'body'
            __getfield_rec(@sel[:body] || [], e1)
          when 'echo' # Send back the command string
            @rspfrm.cut(label: 'Command Echo', val: @echo)
          end
        end

        def ___frame_to_field(e0)
          enclose((e0[:label]).to_s, 'Field:End') do
            if e0[:index]
              ___ary_field(e0) { yield }
            else
              ___str_field(e0, yield)
            end
          end
        end

        # Field
        def ___str_field(e0, data)
          return unless (akey = e0[:assign])
          if e0[:valid] && /#{e0[:valid]}/ !~ data
            warning("Invalid Data (#{data}) for /#{e0[:valid]}/")
          else
            @cache[akey] = data
            verbose { "Assign:[#{akey}] <- #{data.inspect}" }
          end
        end

        # Array
        def ___ary_field(e0)
          akey = e0[:assign] || Msg.cfg_err('No key for Array')
          # Insert range depends on command param
          idxs = e0[:index].map do |e1|
            e1[:range] || "0:#{e1[:size].to_i - 1}"
          end
          enclose("Assign:[#{akey}][", ']') do
            @cache[akey] = __mk_array(idxs, get(akey)) { yield }
          end
        end

        def __mk_array(idx, field)
          # make multidimensional array
          # i.e. idxary=[0,0:10,0] -> @data[0][0][0] .. @data[0][10][0]
          return yield if idx.empty?
          fld = field || []
          f, l = idx[0].split(':').map { |i| expr(i) }
          Range.new(f, l || f).each do |i|
            fld[i] = __mk_array(idx[1..-1], fld[i]) { yield }
            verbose { "Array:Index[#{i}] <- #{fld[i].inspect}" }
          end
          fld
        end
      end
    end

    if __FILE__ == $PROGRAM_NAME
      require 'libfrmcmd'
      ConfOpts.new('[id] [cmd]', options: 'h') do |cfg|
        field = Field.new(cfg.args).ext_local_conv
        field.frame.cmode(cfg.opt.host).load
        atrb = field.dbi.pick(%i(stream)).update(field: field)
        # dbi.pick alreay includes :command, :version
        cobj = Index.new(cfg, atrb)
        cobj.add_rem.add_ext
        ent = cobj.set_cmd(cfg.args)
        begin
          field.conv(ent)
        rescue CommError
          Msg.msg($ERROR_INFO)
        end
        puts field
      end
    end
  end
end
