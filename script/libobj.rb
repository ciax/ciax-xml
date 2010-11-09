#!/usr/bin/ruby
require "libxmldoc"
require "libmodxml"
require "libverbose"
require "libiofile"
require "lib0var"
require "libstatsym"

class Obj < Hash
  include ModXml
  attr_reader :stat

  def initialize(obj)
    @odb=XmlDoc.new('odb',obj)
  rescue SelectID
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
    @value,@gn={},0
    @cs=Var.new(@v)
    @cs.stat={'value'=>@value,'stat'=>@stat }
    @odb['comm'].each_element{|e|
      self[e.name]=e.text
    }
    @sym=StatSym.new(@v)
  end
  
  public
  def setcmd(line)
    ca=line.split(' ')
    if @odb['command']
      begin
        @session=@odb.select_id('command',ca.shift)
        a=@session.attributes
        @v.msg{"Exec(ODB):#{a['label']}"}
        line=[a['ref'],*ca].join(' ')
      rescue
        raise "== Command List ==\n#{$!}"
      end
    end
    yield line.split(' ')
  end
  
  def get_stat(value)
    return unless value
    @value.update(value)
    @odb['status'].each_element{|g| stat_group(g) }
    @stat['time']['val']=@value['time']
    @f.save_json(@stat)
  end

  private
  #Stat Methods
  def stat_group(e)
    case e.name
    when 'group'
      @gn+=1
      e.each_element{|e1| stat_group(e1)}
    when 'title'
      get_var(e)
    when 'repeat'
      @cs.repeat(e){
        e.each_element{|e1| stat_group(e1)}
      }
    end
  end

  def get_var(var) # //status/var
    st={'group' => @gn }
    a=var.attributes
    ref=@cs.sub_var(a['ref'])
    st['title']=@cs.sub_var(var.text)
    st['val']=@value[ref]
    @v.msg{"STAT:GetStatus:#{ref}=[#{st['val']}]"}
    st.update(@sym.get_symbol(a['symbol'],st['val']))
    st.update(@sym.get_level(a['level'],st['val']))
    @stat[ref]=st
  end

end
