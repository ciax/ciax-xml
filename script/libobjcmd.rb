#!/usr/bin/ruby
require "libxmldb"
class ObjCmd < XmlDb
  def initialize(doc)
    super(doc,'//controls')
  end

  def node_with_id(id)
    db=super(id)
    if ref=db.attr['ref']
      return super(ref)
    end
    return db
  end

  def objcmd(par=nil)
    @var['par']=par
    @devcmd=Proc.new
    each_node {|e| e.issue_cmd}
  end

  protected
  def issue_cmd
    cmd=Array.new
    each_node {|e| cmd << e.operate}
    line=cmd.join(' ')
    @v.msg("Exec(DDB):[#{line}]")
    warn "CommandExec[#{line}]"
    @devcmd.call(line)
  end

  def operate
    text_convert {|r,t|
      if ope=attr['operator']
        x=r.to_i
        y=t.hex
        case ope
        when 'and'
          str= x & y
        when 'or'
          str= x | y
        end
        @v.msg("Operate:(#{x} #{ope} #{y})=#{str}")
        return str
      end
      r || t
    }
  end

end

