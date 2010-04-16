#!/usr/bin/ruby
require "libcls"
TopNode='//controls'
class ClsCtrl < Cls

  public
  def set_cmd(id)
    begin
      @doc=@doc.elements[TopNode+"//[@id='#{id}']"] || raise
    rescue
      list_id(TopNode)
      raise("No such a command")
    end
    node_with_name('commandset') {|e| @cmd=e}
    node_with_name('interlock') {|e| @ilk=e}
  end
 
  def set_stat(stat)
    @var.update(stat)
  end

  def clsctrl
    pre_check
    exec_cmdset
    post_check
  end

  protected
  def issue_cmd
    warn "CommandExec[#{self['ref']}]"
  end

  def wait_until
    node_with_name('until') do |e|
      timeout=self['timeout'] ? self['timeout'] : 5
      start=Time.now
      while Time.now - start < timeout.to_i
        e.each_node do |d|
          d.issue_cmd
        end
        e.chk_condition && return
        sleep 1
      end
      warn "Timeout"
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
    sufficient? && return
    required? || raise("Interlock Error")
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

