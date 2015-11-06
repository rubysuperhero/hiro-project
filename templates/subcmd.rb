#!/usr/bin/env ruby

# Subcommands are defined at the bottom
# Each subcommand has its own class
# see: Help

require 'awesome_print'
require 'optparse'

class Options
  def set(k,v)
    k = k.to_sym
    singleton_class.class_eval{ attr_accessor k }
    instance_variable_set("@#{k}", v)
  end

  def method_missing(*asdf)
    false
  end
end

class SubCommand
  module Registration
    def register(klass)
      SubCommand.register klass
    end
  end

  class << self
    attr_accessor :commands
    def process
      commands.find{|cmd|
        cmd.matches?(MainCommand.subcmd)
      }.run
    end

    def register(klass)
      @commands ||= []
      @commands.push(klass)
    end

    def matches?(subcmd)
      possible_matches.include?(subcmd)
    end

    def possible_matches
      %w{ }
    end

    def run
      new.run
    end
  end

  attr_accessor :args, :stdinput, :stdoutput
  attr_accessor :options

  def initialize
    @args = MainCommand.args
    @stdinput = MainCommand.stdinput
    @stdoutput = MainCommand.stdoutput
    @options = MainCommand.options
  end

  def cmd
    self.class.to_s.downcase
  end

  def run
    raise Exception, 'not implemented'
  end

  def debug
    ap cmd: cmd,
      args: args,
      stdinput: stdinput,
      stdoutput: stdoutput,
      options: options
  end
end

module MainCommand
  extend self

  attr_accessor :args, :stdinput, :stdoutput
  attr_accessor :options
  def run(args=ARGV.clone, inp=$stdin, out=$stdout)
    @args, @stdinput, @stdoutput = args, inp, out
    @options = Options.new

    parse_options

    SubCommand.process
  end

  def subcmd
    @subcmd ||= args.shift
  end

  def parse_options
    args.options { |opts|
      opts.on('-h', '--help', 'print this message') do
        @options.set(:help, true)
      end
    }.parse!
  end
end

class Help < SubCommand
  extend SubCommand::Registration
  register self

  class << self
    def possible_matches
      %w{ h help } + [nil]
    end
  end

  def cmd
    'help'
  end

  def run
    puts args.options
  end
end

MainCommand.run

