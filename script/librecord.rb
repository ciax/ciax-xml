#!/usr/bin/ruby
require "libstatus"
require "libcommand"
require "libstep"

module CIAX
  module Mcr
    class Record < Datax
      include PrtShare
      # Level [0] Step, [1] Record & Item, [2] Group, [3] Domain, [4] Command
      attr_reader :cfg
      def initialize(db={})
        super('record',[],'steps')
        self['id']=db['id'] # Project
        self['ver']=db['version'] # Version
      end

      def start(cfg)
        @cfg=type?(cfg,Config)
        self['sid']=self['time'].to_s # Session ID
        self['cid']=@cfg[:cid] # Command ID (cmd:par)
        self['label']=@cfg['label'] # Label for CID
        ext_file(self['sid'])
        self
      end

      def add_step(e1)
        Msg.type?(@cfg[:wat_list],Wat::List)
        step=Step.new(e1,@cfg)
        step.post_upd_procs << proc{post_upd}
        step['time']=Msg.elps_sec(self['time'])
        @data << step
        step
      ensure
        post_upd
      end

      def finish(str)
        self['result']=str
        self['total_time']=Msg.elps_sec(self['time'])
        self
      ensure
        post_upd
      end

      def to_s
        @vmode == 'r' ? super : to_v
      end

      def to_v
        date=Time.at((self['time']/1000).round)
        msg=head("MACRO",3)+" (#{date})\n"
        @data.each{|i| msg << title(i)+result(i) }
        msg
      end
    end

    if __FILE__ == $0
      GetOpts.new('r')
      $opt.usage "(-r) < record_file" if STDIN.tty?
      puts Record.new.read
    end
  end
end
