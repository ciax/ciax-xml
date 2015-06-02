#!/usr/bin/ruby
require "libstatus"
require "libcommand"
require "libstep"

module CIAX
  module Mcr
    class Record < Datax
      # Level [0] Step, [1] Record & Item, [2] Group, [3] Domain, [4] Command
      attr_reader :cfg
      def initialize(id,ver='0')
        super('record',[],'steps')
        self['id']=id # Project ID
        self['ver']=ver # Version
      end

      # cfg will come from Entity, which should have [:cid],['label'],@layers[:wat]
      def start(cfg)
        @cfg=type?(cfg,Config)
        self['sid']=self['time'].to_s # Session ID
        self['cid']=@cfg[:cid] # Command ID (cmd:par)
        self['label']=@cfg['label'] # Label for CID
        ext_file(self['sid'])
        self
      end

      def add_step(e1)
        Msg.type?(@cfg.layers[:wat],Wat::List)
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

      def read(json_str=nil)
        super
        @data.each{|i| i.extend(PrtShare)}
        self
      end

      def to_v
        date=Time.at((self['time']/1000).round)
        msg=Msg.color("MACRO",3)+":#{self['label']} (#{date})\n"
        @data.each{|i| msg << i.title+i.result}
        msg
      end
    end

    if __FILE__ == $0
      GetOpts.new('r')
      $opt.usage "(-r) < record_file" if STDIN.tty?
      puts Record.new('none').read
    end
  end
end
