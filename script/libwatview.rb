#!/usr/bin/ruby
require 'libwatrsp'

# View is not used for computing, just for apperance for user.
# So the convert process (upd) will be included in to_s
module CIAX
  # Watch Layer
  module Wat
    # Decorate the event data (Put caption,symbole,etc.) from WDB
    class View < Upd
      def initialize(event)
        super()
        @event = type?(event, Event)
        wdb = type?(event.dbi, Dbi)[:watch]
        init_stat(wdb || { index: [] })
        @event.post_upd_procs << proc do
          verbose { 'Propagate Event#upd -> upd' }
          upd
        end
      end

      def to_v
        vw = ''
        view_time(vw)
        vw << item('Issuing', self['exec'])
        return vw if self['stat'].empty?
        view_cond(vw)
        vw << item('Interrupt', self['int'])
        vw << item('Blocked', self['block'])
      end

      def to_r
        @event.to_r
      end

      private

      def init_stat(wdb)
        self['stat'] = {}
        wdb[:index].each do |id, evnt|
          hash = (self['stat'][id] ||= {})
          hash['label'] = evnt['label']
          init_cond(evnt[:cnd], (hash['cond'] ||= []))
        end
        self
      end

      def init_cond(cond, m)
        cond.each do |cnd|
          h = Hash[cnd]
          h['cri'] = cnd['val'] if cnd['type'] != 'onchange'
          m << h
        end
        self
      end

      def upd_core
        self['time'] = @event['time']
        %w(exec block int act_start act_end upd_next).each do |id|
          self[id] = @event.get(id)
        end
        upd_stat
        self
      end

      def upd_stat
        self['stat'].each do |id, v|
          upd_cond(id, v['cond'])
          v['active'] = @event.get('active').include?(id)
        end
        self
      end

      def upd_cond(id, cond)
        cond.each_with_index do |h, i|
          v = h['var']
          h['res'] = @event.get('res')[id][i]
          h['val'] = @event.get('crnt')[v]
          h['cri'] = @event.get('last')[v] if h['type'] == 'onchange'
        end
        self
      end

      def view_time(vw)
        vw << item('Elapsed', elps_date(self['time'], now_msec))
        vw << item('ActiveTime', elps_sec(self['act_start'], self['act_end']))
        vw << item('ToNextUpdate', elps_sec(now_msec, self['upd_next']))
      end

      def view_cond(vw)
        vw << item('Conditions')
        self['stat'].values.each do |i|
          vw << cformat("    %:6s\t: %s\n", i['label'], rslt(i['active']))
          view_event(vw, i['cond'])
        end
      end

      def view_event(vw, cond)
        cond.each do |j|
          vw << cformat("      %s %:3s  (%s: %s)\n",
                        rslt(j['res']), j['var'], j['type'], frml(j))
        end
      end

      def frml(j)
        cri = j['cri']
        val = j['val']
        if j['type'] == 'onchange'
          format('%s => %s', cri, val)
        else
          ope = j['inv'] ? '!' : '='
          format('/%s/ %s~ %s', cri, ope, val)
        end
      end

      def rslt(res)
        color(res ? 'o' : 'x', res ? 2 : 1)
      end

      def item(str, res = nil)
        cformat("  %:2s\t: %s\n", str, res)
      end
    end

    if __FILE__ == $PROGRAM_NAME
      require 'libinsdb'
      OPT.parse('r')
      event = Event.new
      begin
        id = STDIN.tty? ? ARGV.shift : event.read['id']
        dbi = Ins::Db.new.get(id)
        event.setdbi(dbi)
        wview = View.new(event)
        event.ext_save.ext_load if STDIN.tty?
        puts STDOUT.tty? ? wview : wview.to_j
      rescue InvalidID
        OPT.usage('(opt) [site] | < event_file')
      end
    end
  end
end
