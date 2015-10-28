#!/usr/bin/env ruby

require 'mechanize'
require 'fileutils'
require 'open-uri'
require 'pp'

class Konachan < BaseRipper
  register :konachan

  class << self
    def url_patterns
      [
        /konachan[.]net/i,
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
    'konachan'
  end

  def ripper_path
    @download_path ||= File.join(base_path, ripper_name)
  end

  def url
    @url ||= args[0] || `pbpaste`
  end

  def folder
    @folder ||= args[1] rescue nil
    @folder ||= url[/tags=[^&]*/][/[^=]+$/] rescue nil
    @folder ||= Date.today.to_s
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
    # mech = Mechanize.new

    tag = folder
    puts "Downloading Tag: '%s'..." % tag
    cd_to folder_path(tag)

    base_url = url[/https?:..[^\/]*/]
    next_link = url
    begin
      puts "Downloading page '%s'..." % next_link
      # doc = mech.get(next_link)
      doc = doc_for_url(next_link) # mech.get(next_link)
      links = doc.links
      next_link = links.find{|a| a.attributes.any?{|k,v| [k,v] == ['class','next_page'] } }
      next_link &&= base_url + next_link.href
      pages = links.select{|a| a.attributes.any?{|k,v| k == 'class' && v =~ /thumb/ } }
      pages.map do |a|
        puts "a.href => #{base_url + a.href}"
        # m = Mechanize.new
        # pg = m.get base_url + a.href
        pg = doc_for_url(base_url + a.href) #m.get base_url + a.href
        img = pg.links.find{|pga| pga.dom_id == 'highres' }

        if img == nil
          puts "CAN NOT FIND #highres on '%s'" % a.href
          next
        end

        filename = "%s" % [File.basename(img.href).sub(/\?.*/,'')]

        if File.exists? filename
          puts "Skip existing file '%s'..." % filename
        else
          puts "Saving '%s'..." % filename
          # m.get(img.href).save_as(filename)
          doc_for_url(img.href).save_as(filename)
        end
      end
    end while next_link
  end

  def open_folders
    download_folders.each do |df|
      system 'open', df
    end
  end

  def docs
    @docs ||= Mash.new
  end

  def doc_for_url(url)
    docs[url] ||= Mechanize.new.get(url)
  end

  # def links
  #   @links ||= doc.links
  # end

  # def images
  #   @images ||= links.select{|a| a.href =~ /(^|\W)i[.]konachan/i }
  # end

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

