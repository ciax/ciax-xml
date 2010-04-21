#!/usr/bin/ruby
require "libxmldb"
require "libctrl"
class ClsCtrl < XmlDb
  include Ctrl
  def initialize(doc)
    super(doc,'//controls')
  end

  public
  def clsctrl
    @devcmd=Proc.new
    node_with_name('commandset') {|e| @cmd=e}
    node_with_name('interlock') {|e| @ilk=e}
    return 1 if pre_check
    exec_cmdset
    post_check
  end

  protected
  def issue_cmd
    warn "CommandExec[#{self['ref']}]"
    @devcmd.call(self['ref'])
  end

  def wait_until
    node_with_name('until') do |e|
      timeout=(self['timeout'] || 5).to_i
      issue=Thread.new(e) do |e|
        loop do
          e.each_node do |d|
            d.issue_cmd
          end
          break if e.chk_condition
          sleep 1
        end
      end
      issue.join(timeout) || warn("Timeout")
    end
  end

  def chk_condition
    vname=self['var']
    stat=@var[vname] || raise(IndexError,"No reference for #{vname}")
    expect=self['value']
    actual=stat['val'] || raise(IndexError,"No status")
    @v.msg "#{self.name}: #{vname} = #{actual} for #{expect}"
    (expect == actual)
  end

  private
  def exec_cmdset
    @cmd.each_node do |e|
      e.issue_cmd
      e.wait_until
    end 
  end

  def pre_check
    return unless @ilk
    if sufficient?
      @v.msg "Command already done -> Skip"
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

