#!/usr/bin/env ruby

require 'awesome_print'

module H
  module Experiment
    extend self

    NAME = 'NAME GOES HERE'

    DESCRIPTION = <<-"END_DESCRIPTION".lines.map(&:strip).join("\n")
      This is a Hero Experiment written in Ruby.
    END_DESCRIPTION

    ABOUT = {
      'Name' => NAME,
      'Description' => DESCRIPTION,
    }

    def about
      ABOUT.each do |key,val|
        heading = key.to_s
        puts
        if val.lines.count == 1
          puts format('%s: %s', heading, val)
        else
          puts format('%s:', heading)
          puts val
        end
      end
      puts
    end

    def test(args=ARGV.clone, inp=$stdin, out=$stdout)
      case args.first
      when *%w{ a about h help }
        about
      else
        puts 'subcommand %s not found' % args.first
      end
    end
  end
end

H::Experiment.test # => "this is where the test code goes"

