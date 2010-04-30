#!/usr/bin/ruby
require "libxmldb"
require "libmodcmd"
class ClsCmd < XmlDb
  include ModCmd
  def initialize(doc)
    super(doc,'//controls')
  end

  public
  def clscmd(par=nil)
    @var['par']=par
    @devcmd=Proc.new
    each_node do |e|
      e.issue_cmd
    end 
  end

  protected
  def issue_cmd
    cmd=Array.new
    each_node do |e|
      cmd << e.operate
    end
    msg "Exec(DDB):[#{cmd.join(' ')}]"
    warn "CommandExec[#{cmd.join(' ')}]"
    @devcmd.call(cmd)
  end

  def operate
    text_convert do |r,t|
      attr_with_key('operator') do |ope|
        x=r.to_i
        y=t.hex
        case ope
        when 'and'
          str= x & y
        when 'or'
          str= x | y
        end
        msg "(#{x} #{ope} #{y})=#{str}"
        return str
      end
      r || t
    end
  end

end
