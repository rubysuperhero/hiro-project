#!/usr/bin/env ruby

require 'mechanize'
require 'fileutils'
require 'open-uri'
require 'pp'

class DeviantArt < BaseRipper
  register :deviant_art

  class << self
    def url_patterns
      [
        /deviantart[.]com/i,
      ]
    end

    def matches?(url=`pbpaste`)
      return true if url_patterns.any?{|re| url[re] }
      false
    end

    def rip(args=ARGV.clone)
      new(args).tap(&:rip)
    end
  end

  attr_accessor :args
  def initialize(args=ARGV.clone)
    @args = args

    parse_options

    cd_to ripper_path
  end

  def ripper_name
    'deviant_art'
  end

  def ripper_path
    @download_path ||= File.join(base_path, ripper_name)
  end

  def url
    @url ||= args[0] || `pbpaste`
  end

  def folder
    @folder ||= args[1] rescue nil
  end

  # def rip
  #   puts "Downloading Album: '%s'..." % album
  #   images.map do |a|
  #     filename = File.basename(a.href)
  #     if File.exists? filename
  #       puts "Skipping existing file: '%s'..." % filename
  #     else
  #       puts "Saving '%s'..." % filename
  #       img = a.href[/^\/\//] && 'http:' + a.href || a.href
  #       IO.binwrite(filename, open(img).read)
  #     end
  #   end
  # end

  def rip
    mech = Mechanize.new

    album = folder || url.sub(/https?:../,'').split(/\/|\./).first
    puts "Downloading Album: '%s'..." % album
    FileUtils.mkdir_p album

    base_url = url[/https?:..[^\/]*/]
    next_link = url
    begin
      puts "Downloading page '%s'..." % next_link
      doc = mech.get(next_link)
      links = doc.links
      next_link = links.find{|a| a.text == 'Next' && a.attributes.any?{|k,v| v == 'away' } && a.href =~ /[^c]offset/ }
      next_link &&= base_url + next_link.href
      pages = links.select{|a| a.attributes.any?{|attr| attr == ['class','t'] } }
      pages.map do |a|
        puts "a.href => #{a.href}"
        m = Mechanize.new
        pg = m.get a.href
        img = pg.links.find{|pga| pga.attributes.any?{|k,v| k == 'class' && v =~ /dev.page.download/i }}
        next if img == nil
        filename = "%s/%s" % [album, File.basename(img.href).sub(/\?.*/,'')]
        if File.exists? filename # unless File.exists? filename
          puts "Skipping existing file: '%s'..." % filename
        else
          puts "Saving '%s'..." % filename
          m.get(img.href).save_as(filename)
        end
      end
    end while next_link
  end

  def doc
    @doc ||= Mechanize.new.get(url)
  end

  def links
    @links ||= doc.links
  end

  def images
    @images ||= links.select{|a| a.href =~ /(^|\W)i[.]deviant_art/i }
  end

  def parse_options
    return if options.parsed

    args.options { |opts|
      opts.on('-h', '--help', 'print this message') do
        options.show_help = true
      end
    }.parse!

    options.parsed = true
  end

  def options
    @options ||= OpenStruct.new.tap do |opts|
      # default options go here
      # or pass them to #new as a hash

      opts.show_help = false
      opts.parsed = false
    end
  end
end

