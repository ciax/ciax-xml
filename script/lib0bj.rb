#!/usr/bin/ruby
require "libxmldoc"
require "libverbose"
require "libiofile"
require "libmodxml"
require "libconvstr"
require "lib0bjstat"

class Obj < Hash
  include ModXml
  include ObjStat
  attr_reader :stat

  def initialize(obj)
    @odb=[XmlDoc.new('0db',obj)]
    if robj=@odb.first['ref']
      @odb << XmlDoc.new('0db',robj)
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
    @cs.stat={'field'=>@field,'stat'=>@stat }
    @odb.first['comm'].each_element{|e|
      self[e.name]=e.text
    }
  end
  
  public
  def setcmd(line)
    ca=line.split(' ')
    cmd=ca.shift
    @cs.par=ca
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
        repeat_cmd(c){|d| yield d }
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
  def repeat_cmd(e)
    @cs.repeat(e){|f|
      case f.name
      when 'statement'
        yield(get_cmd(f))
      when 'repeat'
        repeat_cmd(f){|g| yield g }
      end
    }
  end

  def get_cmd(e) # //statement
    ary=[]
    e.each_element{|d| # //argv
      str=@cs.sub_var(d.text)
      case d.name
      when 'formula'
        str=format(d,eval(str))
      end
      ary << str
    }
    cmd = ary.join(' ')
    @v.msg{"Exec(DDB):[#{cmd}]"}
    cmd
  end

end
