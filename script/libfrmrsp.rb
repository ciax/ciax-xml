#!/usr/bin/ruby
require "libfield"
require "libframe"
require "libstream"

# Rsp Methods
# Input  : upd block(frame,time)
# Output : Field
module Frm
  module Rsp
    extend Msg::Ver
    # Var::Load@db is needed
    def self.extended(obj)
      init_ver('FrmRsp',6)
      Msg.type?(obj,Field::Var,Var::Load)
    end

    def init(cobj)
      @cobj=Msg.type?(cobj,Command)
      self.ver=@db['frm_ver'].to_i
      rsp=@db.deep_copy[:rspframe]
      @sel=Hash[rsp[:frame]]
      @fds=rsp[:select]
      @frame=Frame.new(@db['endian'],@db['ccmethod'])
      # Field Initialize
      rsp[:assign].each{|k,v|
        self.val[k]||=v
      }
    end

    # Block accepts [frame,time]
    # Result : executed block or not
    def upd
      if rid=@cobj.current[:response]
        @sel[:select]=@fds[rid]|| Msg.cfg_err("No such response id [#{rid}]")
        hash=yield
        frame=hash[:data]
        set_time(hash[:time]) #Field::set_time
        Msg.com_err("No Response") unless frame
        if tm=@sel['terminator']
          frame.chomp!(eval('"'+tm+'"'))
          Rsp.msg{"Remove terminator:[#{frame}] by [#{tm}]" }
        end
        if dm=@sel['delimiter']
          @fary=frame.split(eval('"'+dm+'"'))
          Rsp.msg{"Split:[#{frame}] by [#{dm}]" }
        else
          @fary=[frame]
        end
        @frame.set(@fary.shift)
        getfield_rec(@sel[:main])
        if cc=unset('cc') #Field::unset
          cc == @cc || Msg.com_err("Verify:CC Mismatch <#{cc}> != (#{@cc})")
          Rsp.msg{"Verify:CC OK <#{cc}>"}
        end
        Rsp.msg{"Rsp/Update(#{get('time')})"} #Field::get
        true
      else
        Rsp.msg{"Send Only"}
        @sel[:select]=nil
        false
      end
    end

    def upd_logline(str)
      res=Logging.set_logline(str)
      @cobj.set(res[:cmd])
      upd{res}
    end

    private
    # Process Frame to Field
    def getfield_rec(e0)
      e0.each{|e1|
        case e1
        when 'ccrange'
          begin
            Rsp.msg(1){"Entering Ceck Code Node"}
            @frame.mark
            getfield_rec(@sel[:ccrange])
            @cc = @frame.checkcode
          ensure
            Rsp.msg(-1){"Exitting Ceck Code Node"}
          end
        when 'select'
          begin
            Rsp.msg(1){"Entering Selected Node"}
            getfield_rec(@sel[:select])
          ensure
            Rsp.msg(-1){"Exitting Selected Node"}
          end
        when Hash
          frame_to_field(e1){ cut(e1) }
        end
      }
    end

    def frame_to_field(e0)
      Rsp.msg(1){"Field:#{e0['label']}"}
      if e0[:index]
        # Array
        key=e0['assign'] || Msg.cfg_err("No key for Array")
        # Insert range depends on command param
        idxs=e0[:index].map{|e1|
          @cobj.current.subst(e1['range'])
        }
        begin
          Rsp.msg(1){"Array:[#{key}]:Range#{idxs}"}
          @val[key]=mk_array(idxs,get(key)){yield}
        ensure
          Rsp.msg(-1){"Array:Assign[#{key}]"}
        end
      else
        #Field
        data=yield
        if key=e0['assign']
          @val[key]=data
          Rsp.msg{"Assign:[#{key}] <- <#{data}>"}
        end
      end
    ensure
      Rsp.msg(-1){"Field:End"}
    end

    def mk_array(idx,field)
      # make multidimensional array
      # i.e. idxary=[0,0:10,0] -> @field.val[0][0][0] .. @field.val[0][10][0]
      return yield if idx.empty?
      fld=field||[]
      f,l=idx[0].split(':').map{|i| eval(i)}
      Range.new(f,l||f).each{|i|
        fld[i] = mk_array(idx[1..-1],fld[i]){yield}
        Rsp.msg{"Array:Index[#{i}]=#{fld[i]}"}
      }
      fld
    end

    def cut(e)
      @frame.cut(e) || @frame.set(@fary.shift).cut(e) || ''
    end
  end
end

class Field::Var
  def ext_rsp(cobj)
    extend(Frm::Rsp).init(cobj)
  end
end

if __FILE__ == $0
  require "liblocdb"
  require "libcmdext"
  Msg.getopts("m",{'m' => 'merge file'})
  Msg.usage "(opt) < logline",*$optlist if STDIN.tty? && ARGV.size < 1
  str=gets(nil) || exit
  logdata=Logging.set_logline(str)
  id=logdata[:id]
  fdb=Loc::Db.new(id)[:frm]
  cobj=Command.new
  cobj.add_ext(fdb,:cmdframe)
  field=Field::Var.new.ext_file(fdb)
  field.load if $opt['m']
  field.ext_rsp(cobj)
  field.upd_logline(str)
  puts field
  exit
end
