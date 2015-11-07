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

module MainCommand
  extend self

  attr_accessor :args, :stdinput, :stdoutput
  attr_accessor :options
  def run(args=ARGV.clone, inp=$stdin, out=$stdout)
    @args, @stdinput, @stdoutput = args, inp, out
    @options = Options.new

    parse_options

    process
  end

  def process
    case subcmd
    when 'h', 'help'
      run_help
    else
      raise Exception, format('%s not found', subcmd)
      exit 1
    end
    exit 0
  end

  def run_help
    puts args.options
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

MainCommand.run

