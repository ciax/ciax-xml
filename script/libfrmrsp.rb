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
      def ext_rsp(id,db)
        ext_file(id)
        @ver_color=3
        @db=type?(db,Db)
        fdbr=db[:response]
        self['ver']=db['version'].to_i
        @sel=Hash[fdbr[:frame]]
        @fds=fdbr[:index]
        @frame=Frame.new(db['endian'],db['ccmethod'],@sel['terminator'],@sel['delimiter'])
        # Field Initialize
        if @data.empty?
          db[:field].each{|id,val|
            @data[id]=val['val']||Arrayx.new.skeleton(val[:struct])
          }
        end
        self
      end

      # Block accepts [frame,time]
      # Result : executed block or not
      def rcv(ent)
        @current_ent=type?(ent,Entity)
        if rid=ent.cfg['response']
          @fds.key?(rid) || Msg.cfg_err("No such response id [#{rid}]")
          @sel[:body]=@fds[rid][:body]||[]
          stream=yield
          @frame.set(stream[:data])
          @cache=@data.deep_copy
          getfield_rec(@sel[:main])
          @frame.cc_check(@cache.delete('cc'))
          @data=@cache
          self['time']=stream['time']
          verbose("FrmRsp","Updated(#{self['time']})") #Field::get
        else
          verbose("FrmRsp","Send Only")
          @sel[:body]=nil
        end
        self
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
              getfield_rec(@sel[:body])
            }
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
              @current_ent.subst(e1['range'])
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
            @frame.verify(e0)
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
      def ext_rsp(id,db)
        extend(Frm::Rsp).ext_rsp(id,db)
      end
    end

    if __FILE__ == $0
      require "liblocdb"
      require "libfrmcmd"
      GetOpts.new("",{'m' => 'merge file','l' => 'get from logline'})
      if $opt['l']
        $opt.usage("-l < logline") if STDIN.tty?
        str=gets(nil) || exit
        res=Logging.set_logline(str)
        id=res['id']
        cid=res['cmd']
      elsif STDIN.tty? || ARGV.size < 2
        $opt.usage("(opt) [id] [cmd] (par..) < string")
      else
        id=ARGV.shift
        cid=ARGV.shift
        res={'time'=>now_msec}
        res[:data]=gets(nil) || exit
      end
      fdb=Loc::Db.new.set(id)[:frm]
      fobj=Command.new(Config.new.update(:db => fdb))
      ent=fobj.set_cmd(cid.split(':'))
      field=Field.new.ext_rsp(id,fdb)
      field.load if $opt['m']
      field.rcv(ent){res}.upd
      puts field
      exit
    end
  end
end
