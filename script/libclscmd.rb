#!/usr/bin/ruby
require "libxmldb"
require "libmodcmd"
class ClsCmd < XmlDb
  include Ctrl
  def initialize(doc)
    super(doc,'//controls')
  end

  public
  def clscmd
    @devcmd=Proc.new
    node_with_name('commandset') {|e| @cmd=e}
    node_with_name('interlock') {|e| @ilk=e}
    return 1 if pre_check
    exec_cmdset
    post_check
  end

  protected
  def issue_cmd
    cmd=Array.new
    each_node do |e|
      cmd << e.operate(e.text)
    end
    @v.msg "Exec(DDB):[#{cmd}]"
    warn "CommandExec[#{cmd}]"
    @devcmd.call(cmd)
  end

  def wait_until
    timeout=(self['timeout'] || 5).to_i
    issue=Thread.new do
      loop do
        each_node do |d|
          d.issue_cmd
        end
        break if chk_condition
        sleep 1
      end
    end
    issue.join(timeout) || warn("Timeout")
  end

  def chk_condition
    vname=self['var']
    stat=@var[vname] || raise(IndexError,"No reference for #{vname}")
    expect=self['value']
    actual=stat['val'] || raise(IndexError,"No status")
    @v.msg "#{self.name}: #{vname} = #{actual} for #{expect}"
    (expect == actual)
  end

  def operate(str)
    attr_with_key('operator') do |ope|
      x=str.to_i
      y=@doc.text.hex
      case ope
        when 'and'
        str=x & y
        when 'or'
        str=x | y
      end
      @v.msg "(#{x} #{ope} #{y})=#{str}"
    end
    str
  end

  private
  def exec_cmdset
    @cmd.each_node do |e|
      case e.name
      when 'command'
        e.issue_cmd
      when 'wait_until'
        e.wait_until
      end
    end 
  end

  def pre_check
    return unless @ilk
    if sufficient?
      @v.msg "Command already done -> Skip"
      warn "Skip"
      return 1
    end
    raise("Interlock Error") unless required?
  end

  def post_check
    return unless @ilk
    sufficient?(1) || raise("Command incomplete")
  end
  
  def sufficient?(ret=nil)
    @ilk.node_with_name('sufficient') do |d|
      d.chk_condition || return
      ret=1
    end
    return ret
  end
  
  def required?
    @ilk.node_with_name('requied') do |d|
      d.chk_condition || return
    end
    return 1
  end

end




