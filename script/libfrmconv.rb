#!/usr/bin/env ruby
require 'libfrmstat'
require 'libfrmcut'
require 'libfrmsel'

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
          @seldb = Select.new(type?(@dbi, Dbi), :response)
          self
        end

        # Convert with corresponding cmd
        def conv(ent)
          frmsrc = @frame.get(ent.id)
          return self unless frmsrc
          # CutFrame structure:
          #   main(total){ ccrange{ body(selected str) } }
          # terminator: frame pointer will jump to terminator
          #   when no length or delimiter is specified
          @rspfrm = CutFrame.new(frmsrc.dup, @dbi[:stream])
          ___make_data(ent.deep_subst(@seldb.get(ent[:response])))
          verbose { 'Conversion Frame -> Field' }
          self
        end

        private

        def ___make_data(sel)
          @cache = _dic.deep_copy
          __each_field(sel)
          @rspfrm.cc_check(@cache.delete('cc'))
          _dic.replace(@cache)
        end

        # Process Frame to Field
        def __each_field(e0)
          e0.each do |e1|
            if e1.is_a? Array
              ___each_ccrange(e1)
            else
              ___getfield(e1)
            end
          end
        end

        def ___each_ccrange(e1)
          enclose('CCRange:[', ']') do
            @rspfrm.cc_start
            __each_field(e1)
            @rspfrm.cc_reset
          end
        end

        def ___getfield(e1)
          case e1[:type]
          when 'verify'
            @rspfrm.cut(e1)
          when 'assign'
            ___frame_to_field(e1) { @rspfrm.cut(e1) }
          when 'echo' # Send back the command string
            @rspfrm.cut(label: 'Command Echo', val: @echo)
          end
        end

        def ___frame_to_field(e1)
          enclose((e1[:label]).to_s, 'Field:End') do
            if e1[:index]
              ___ary_field(e1) { yield }
            else
              ___str_field(e1, yield)
            end
          end
        end

        # Field
        def ___str_field(e1, data)
          if e1[:valid] && /#{e1[:valid]}/ !~ data
            warning("Invalid Data (#{data}) for /#{e1[:valid]}/")
          else
            ref = e1[:ref]
            @cache[ref] = data
            verbose { "Assign:[#{ref}] <- #{data.inspect}" }
          end
        end

        # Array
        def ___ary_field(e1)
          ref = e1[:ref] || Msg.cfg_err('No key for Array')
          enclose("Assign:[#{ref}][", ']') do
            @cache[ref] = __mk_array(e1[:index], get(ref)) { yield }
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
