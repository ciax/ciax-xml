#!/usr/bin/ruby
require "libxmldoc"
require "libverbose"
require "libiofile"
require "libmodxml"
require "libconvstr"
require "libobjstat"

class Obj < Hash
  include ModXml
  include ObjStat
  attr_reader :stat

  def initialize(obj)
    @odb=[XmlDoc.new('odb',obj)]
    if robj=@odb.first['ref']
      @odb << XmlDoc.new('odb',robj)
    end
  rescue RuntimeError
    abort $!.to_s
  else
    @f=IoFile.new(obj)
    begin
      @stat=@f.load_json
    rescue
      warn $!
      @stat={'time'=>{'label'=>'LAST UPDATE','type'=>'DATETIME'}}
    end
    @v=Verbose.new("odb/#{obj}".upcase)
    @field,@gn={},0
    @cs=ConvStr.new(@v)
    @cs.var={'field'=>@field,'stat'=>@stat }
    @odb.first['comm'].each_element{|e|
      self[e.name]=e.text
    }
  end
  
  public
  def setcmd(line)
    cmd,*@cs.par=line.split(' ')
    ref=nil
    @odb.each{|db|
      next unless db['selection']
      @session=db.select_id('selection',cmd)
      a=@session.attributes
      @v.msg{"Exec(DDB):#{a['label']}"}
      cmd=a['ref'] || break
    }
    line
  rescue
    raise "== Command List ==\n#{$!}"
  end

  def objcom
    @session.each_element {|c|
      case c.name
      when 'parameters'
        pary=@cs.par.clone
        c.each_element{|d| #//par
          validate(d,pary.shift)
        }
      when 'statement'
        yield(get_cmd(c))
      when 'repeat'
        @cs.repeat(c){|d| yield(get_cmd(d))}
      end
    }
  end
  
  def get_stat(dstat)
    return unless dstat
    @field.update(dstat)
    @odb.first['status'].each_element{|g| stat_group(g) }
    @stat['time']['val']=Time.at(@field['time'].to_f).to_s
    @f.save_json(@stat)
  end
  
  private
  #Cmd Method
  def get_cmd(e) # //statement
    cmd=''
    argv=[]
    e.each_element{|d| # //argv
      str=@cs.subnum(d.text).subpar.subvar.eval.to_s
      @v.msg{"CMD:Evaluated [#{str}]"}
      argv << str
    }
    cmd = e.attributes['format'] % argv
    @v.msg{"Exec(DDB):[#{cmd}]"}
    cmd
  end

end
