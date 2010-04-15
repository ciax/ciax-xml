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
    node_with_name('commands') {|e| @cmd=e}
    node_with_name('interlock') {|e| @ilk=e}
  end
 
  def set_stat(stat)
    @var.update(stat)
  end

  def clsctrl
    pre_check
    get_cmdset
#    post_check
  end

  protected
  def get_cmdset
    @cmd.each_node do |e|
      puts e['ref']
      e.each_node do |d|
        puts d.name
      end
    end 
  end

  def pre_check
    return unless @ilk
    suf=1;done=0
    @ilk.node_with_name('sufficient') do |d|
      done=1
      begin
        d.chk_condition
      rescue
        suf=0
      end
    end
    return 1 if suf == 1 and done == 1
    @ilk.node_with_name('required') do |d|
      d.chk_condition
    end
  end

  def post_check
    return unless @ilk
    @ilk.node_with_name('sufficient') do |d|
      d.chk_condition
    end
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
    actual=@var[vname]['val'] || raise(IndexError,"No status")
    msg="#{self.name}: #{vname} = #{actual} (expected:#{expect})"
    @v.msg(msg)
    raise(msg) if expect != actual
  end

end

