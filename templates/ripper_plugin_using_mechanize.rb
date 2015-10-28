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
        /deviant_art[.]com/i,
      ]
    end

    def matches?(url=`pbpaste`)
      return true if url_patterns.any?{|re| url[re] }
      false
    end

    def rip(args=ARGV.clone)
      new(args).tap(&:rip).tap(&:open_folders)
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

  def default_folder
    Date.today.to_s.tap do |f|
      folder_path(f)
    end
  end

  def folder_path(folder)
    File.join(ripper_path, folder).tap do |f|
      FileUtils.mkdir_p(f, verbose: true)
      download_folders.push f unless download_folders.include? f
    end
  end

  def download_folders
    @download_folders ||= []
  end

  def open_folders
    download_folders.each do |df|
      system 'open', df
    end
  end

  def rip
    puts "Downloading Album: '%s'..." % album
    images.map do |a|
      filename = File.basename(a.href)
      if File.exists? filename
        puts "Skipping existing file: '%s'..." % filename
      else
        puts "Saving '%s'..." % filename
        img = a.href[/^\/\//] && 'http:' + a.href || a.href
        IO.binwrite(filename, open(img).read)
      end
    end
  end

  def doc
    @doc ||= Mechanize.new.get(url)
  end

  def doc_for_url(url)
    docs[url] ||= Mechanize.new.get(url)
  end

  def docs
    @docs ||= {}.to_mash
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

