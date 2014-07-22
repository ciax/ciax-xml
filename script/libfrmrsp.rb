#!/usr/bin/ruby
require "libfield"
require "libframe"
require "libstream"

# Rsp Methods
# Input  : upd block(frame,time)
# Output : Field
module CIAX
  module Frm
    module Rsp
      # @< (base),(prefix)
      # @ cobj,sel,fds,frame,fary,cc
      def self.extended(obj)
        Msg.type?(obj,Field)
      end

      # Ent is needed which includes response_id and cmd_parameters
      def ext_rsp
        @ver_color=3
        fdbr=@db[:response]
        @skel=fdbr[:frame]
        # @sel structure: { terminator, :main{}, :body{} <- changes on every upd }
        @fds=fdbr[:index]
        @frame=Frame.new(@db['endian'],@db['ccmethod'],@skel['terminator'])
        # terminator: frame pointer will jump to terminator if no length or delimiter is specified
        self
      end

      # Block accepts [frame,time]
      # Result : executed block or not
      def upd(ent)
        @sel=Hash[@skel]
        if rid=type?(ent,Entity).cfg['response']
          @fds.key?(rid) || Msg.cfg_err("No such response id [#{rid}]")
          @sel.update(@fds[rid])
          @sel[:body]=ent.deep_subst(@sel[:body])
          verbose("FrmRsp","Selected DB for #{rid} #{@sel}")
          # Frame structure: main(total){ ccrange{ body(selected str) } }
          stream=yield
          @frame.set(stream.binary,@sel['length'],@sel['padding'])
          @cache=@data.deep_copy
          if @fds[rid].key?('noaffix')
            getfield_rec(['body'])
          else
            getfield_rec(@sel[:main])
            @frame.cc_check(@cache.delete('cc'))
          end
          @data=@cache
          self['time']=stream['time']
          verbose("FrmRsp","Updated(#{self['time']})") #Field::get
        else
          verbose("FrmRsp","Send Only")
        end
        self
      ensure
        post_upd
      end

      private
      # Process Frame to Field
      def getfield_rec(e0)
        e0.each{|e1|
          case e1
          when 'ccrange'
            enclose("FrmRsp","Entering Ceck Code Node","Exitting Ceck Code Node"){
              @frame.cc_mark
              getfield_rec(@sel[:ccrange])
              @frame.cc_set
            }
          when 'body'
            enclose("FrmRsp","Entering Body Node","Exitting Body Node"){
              getfield_rec(@sel[:body]||[])
            }
          when 'echo'
            verbose("FrmRsp","Set Command Echo [#{@echo.inspect}]")
            @frame.cut('label' => 'Command Echo','val' => @echo)
          when Hash
            frame_to_field(e1){ @frame.cut(e1) }
          end
        }
      end

      def frame_to_field(e0)
        enclose("FrmRsp","#{e0['label']}","Field:End"){
          if e0[:index]
            # Array
            akey=e0['assign'] || Msg.cfg_err("No key for Array")
            # Insert range depends on command param
            idxs=e0[:index].map{|e1|
              e1['range']||"0:#{e1['size'].to_i-1}"
            }
            enclose("FrmRsp","Array:[#{akey}]:Range#{idxs}","Array:Assign[#{akey}]"){
              @cache[akey]=mk_array(idxs,get(akey)){yield}
            }
          else
            #Field
            data=yield
            if akey=e0['assign']
              @cache[akey]=data
              verbose("FrmRsp","Assign:[#{akey}] <- <#{data}>")
            end
          end
        }
      end

      def mk_array(idx,field)
        # make multidimensional array
        # i.e. idxary=[0,0:10,0] -> @data[0][0][0] .. @data[0][10][0]
        return yield if idx.empty?
        fld=field||[]
        f,l=idx[0].split(':').map{|i| eval(i)}
        Range.new(f,l||f).each{|i|
          fld[i] = mk_array(idx[1..-1],fld[i]){yield}
          verbose("FrmRsp","Array:Index[#{i}]=#{fld[i]}")
        }
        fld
      end
    end

    class Field
      def ext_rsp
        extend(Frm::Rsp).ext_rsp
      end
    end

    if __FILE__ == $0
      require "libsitedb"
      require "liblogging"
      require "libfrmcmd"
      GetOpts.new("",{'m' => 'merge file'})
      if STDIN.tty?
        $opt.usage("(opt) < logline")
      else
        str=gets(nil) || exit
        res=Logging.set_logline(str)
        id=res['id']
        cid=res['cmd']
      end
      fdb=Site::Db.new.set(id)[:fdb]
      field=Field.new.set_db(fdb).ext_rsp
      field.ext_file if $opt['m']
      if cid
        cfg=Config.new('frm_top').update(:db => fdb,:field => field)
        cobj=Frm::Command.new(cfg)
        ent=cobj.set_cmd(cid.split(':'))
        field.upd(ent){res}
      end
      puts STDOUT.tty? ? field : field.to_j
      exit
    end
  end
end
