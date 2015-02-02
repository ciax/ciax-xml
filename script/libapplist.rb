#!/usr/bin/ruby
require "libappexe"
require "libfrmlist"

module CIAX
  module App
    class List < Site::List
      def initialize(upper=nil)
        super(App,upper)
        @cfg.layers[:app]=self
        Frm::List.new(@cfg)
      end

      def add(id)
        @cfg[:db]||=@cfg[:ldb].set(id)[:adb]
        @cfg[:sqlog]||=SqLog::Save.new(id,'App') if $opt['e']
        set(id,App.new(@cfg))
      end
    end

    class Jump < LongJump; end

    if __FILE__ == $0
      ENV['VER']||='initialize'
      GetOpts.new('chlset')
      begin
        List.new.shell(ARGV.shift)
      rescue InvalidID
        $opt.usage('(opt) [id]')
      end
    end
  end
end
