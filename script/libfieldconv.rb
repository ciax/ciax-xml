#!/usr/bin/env ruby
require 'libfield'
require 'libfrmrsp'
require 'libstream'

# Conv Methods
# Input  : upd block(frame,time)
# Output : Field
module CIAX
  # Frame Layer
  module Frm
    # Field class
    class Field
      def ext_local_conv(stream)
        extend(Conv).ext_local_conv(stream)
      end

      # Frame Response module
      module Conv
        # @< (base),(prefix)
        # @ cobj,sel,fds,frame,fary,cc
        def self.extended(obj)
          Msg.type?(obj, Field)
        end

        # Ent is needed which includes response_id and cmd_parameters
        def ext_local_conv(stream)
          @stream = type?(stream, Hash)
          type?(@dbi, Dbi)
          @fdbr = @dbi[:response]
          @fds = @fdbr[:index]
          init_time2cmt(@stream)
          self
        end

        # Convert with corresponding cmd
        def conv(ent)
          rid = type?(ent, CmdBase::Entity)[:response]
          @fds.key?(rid) || Msg.cfg_err("No such response id [#{rid}]")
          ___make_sel(ent, rid)
          # Frame structure:
          #   main(total){ ccrange{ body(selected str) } }
          # terminator: frame pointer will jump to terminator
          #   when no length or delimiter is specified
          @rspfrm = RspFrame.new(@stream.binary, @dbi[:stream])
          ___make_data(rid)
          verbose { 'Propagate Stream#rcv Field#conv(cmt)' }
          self
        ensure
          cmt
        end

        private

        # sel structure:
        #   { terminator, :main{}, :body{} <- changes on every upd }
        def ___make_sel(ent, rid)
          @sel = Hash[@fdbr[:frame]]
          @sel.update(@fds[rid])
          @sel[:body] = ent.deep_subst(@sel[:body])
          verbose { "Selected DB for #{rid}\n" + @sel.inspect }
        end

        def ___make_data(rid)
          @cache = self[:data].deep_copy
          if @fds[rid].key?(:noaffix)
            __getfield_rec(['body'])
          else
            __getfield_rec(@sel[:main])
            @rspfrm.cc_check(@cache.delete('cc'))
          end
          self[:data] = @cache
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
            verbose { "Assign:[#{akey}] <- <#{data}>" }
          end
        end

        # Array
        def ___ary_field(e0)
          akey = e0[:assign] || Msg.cfg_err('No key for Array')
          # Insert range depends on command param
          idxs = e0[:index].map do |e1|
            e1[:range] || "0:#{e1[:size].to_i - 1}"
          end
          enclose("Array:[#{akey}]:Range#{idxs}", "Array:Assign[#{akey}]") do
            @cache[akey] = __mk_array(idxs, self[:data][akey]) { yield }
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
            verbose { "Array:Index[#{i}]=#{fld[i]}" }
          end
          fld
        end
      end
    end

    if __FILE__ == $PROGRAM_NAME
      require 'libfrmcmd'
      require 'libjslog'
      ConfOpts.new('< logline', m: 'merge file') do |cfg|
        raise(InvalidARGS, '  Need Input File') if STDIN.tty?
        res = Varx::JsLog.read(gets(nil))
        field = Field.new(res[:id]).ext_local_conv(res)
        field.ext_local.ext_save if cfg.opt[:m]
        if (cid = res[:cmd])
          atrb = field.dbi.pick(%i(stream))
          atrb[:field] = field
          # dbi.pick alreay includes :command, :version
          cobj = Index.new(cfg, atrb)
          cobj.add_rem.add_ext
          ent = cobj.set_cmd(cid.split(':'))
          begin
            field.conv(ent)
          rescue CommError
            Msg.msg($ERROR_INFO)
          end
        end
        puts field
      end
    end
  end
end
