#!/usr/bin/ruby
require "libxmldb"
require "libmodcmd"
require "libmodfile"
include ModFile

class McrIlk < XmlDb
  include ModCmd
  attr_accessor :mcr,:state,:process,:stat

  def initialize(doc)
    super(doc,'//macro_group')
    @state='ready'
    @process=''
    @mcr=''
    @stat=load_stat(@property['id'])
  end

  public
  def setmcr(id)
    begin
      e=node_with_id(id).child_node
      p "SETID #{id}"
      e.mcr=id
      e.state='check'
      return e
    rescue
      puts $!
      clone
    end
  end

  def set_stat!(stat)
    @stat.update(stat)
    msg "Status Reading"
  end

  def prompt
    print "#{@state}:#{@mcr}:#{@process}>"
  end

  def mcrproceed
p self
    case @state
    when 'ready'
      return 1
    when 'check'
      checking
    when 'issue'
      @state='check'
    when 'wait'
      @wait.checking
      return 1
    end
    msg "Next Step"
    next_node! || @state='ready'
  end

  def checking
    @process=self.name
    case @process
    when 'break'
      if chk_condition
        puts "Skip/Break"
        @state='ready'
        @mcr=''
        return 1
      end
    when 'pass'
      chk_condition || raise("Interlock Error")
      puts "Pass"
    when 'session'     
      issue_cmd
      @state='issue'
    when 'wait'
      puts "Waiting"
      @state='wait'
      @wait=clone
    end
  end

  protected
  def issue_cmd
    cmd=Array.new
    each_node do |e|
      cmd << e.text
    end
    msg "Exec(CDB):[#{cmd.join(' ')}]"
    warn "SessionExec[#{cmd.join(' ')}]"
    @devcmd.call(cmd)
  end

  def wait_until
    timeout=(self['timeout'] || 5).to_i
    msg "Waiting"
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
    case self['combination']
    when 'or'
      each_node do |e|
        e.chk_item || return
      end
    else
      each_node do |e|
        e.chk_item && return
      end
    end
    return 1
  end

  def chk_item
    id=self['stat']
    stat=@stat[id] || raise(IndexError,"No reference for #{id}")
    field=self['field'] || 'val'
    actual=stat[field] || raise(IndexError,"No status")
    regexp=self.text || raise(IndexError,"No expression")
    msg "#{self.name}: #{id} = #{actual} for #{regexp}"
    (/#{regexp}/ =~ actual)
  end

end
