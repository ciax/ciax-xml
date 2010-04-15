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
  def issue_cmd(cmd)
    puts "CommandExec[#{cmd}]"
  end

  def wait_until(timeout,wait_for,update)
    start=Time.now
    while Time.now - start < timeout
      update.each do |cmd|
        issue_cmd(cmd)
        wait_for.each do |key,val|
          return if @var[key] == val
        end
      end
      sleep 1
    end
  end

  def exec_cmdset
    @cmd.each_node do |e|
      timeout=e['timeout'] ? e['timeout'] : 5
      update=Array.new
      wait_for=Array.new
      e.each_node do |d|
        case d.name
        when 'update'
          update << d['ref']
        when 'until'
          wait_for << {d['var'] => d['value']}
        end
      end
      issue_cmd(e['ref'])
      wait_until(timeout,wait_for,update)
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

  def proceed?(cmd)
    e=@doc.elements["commands//[@ref='#{cmd}']/until"]
    return 1 unless e
    a=e.attributes
    vname=a['var']
    stat=@var[vname] || raise(IndexError,"No reference for #{vname}")
    expect=a['value']
    actual=@var[vname]['val'] || raise(IndexError,"No status")
    @v.msg "waiting: #{vname} = #{expect} (actual:#{actual})"
    return 1 if expect == actual 
  end

  def chk_condition
    vname=self['var']
    stat=@var[vname] || raise(IndexError,"No reference for #{vname}")
    expect=self['value']
    actual=stat['val'] || raise(IndexError,"No status")
    @v.msg "#{self.name}: #{vname} = #{actual} (expected:#{expect})"
    (expect == actual)
  end

end

