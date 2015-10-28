#!/usr/bin/env ruby

require 'mechanize'
require 'fileutils'
require 'open-uri'
require 'pp'
require 'pry'

class MangaStream < BaseRipper
  register :manga_stream

  class << self
    def url_patterns
      [
        /mangastream[.]com/i,
        /readms[.]com/i,
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
    'manga_stream'
  end

  def ripper_path
    @download_path ||= File.join(base_path, ripper_name)
  end

  def url
    @url ||= args[0] || `pbpaste`
  end

  def parse_url(url)
    url_parts = url.sub(/^(https?:..)?[^\/]*[.]com\/(r\/)?/, '').split(?/)
    {
      manga: url_parts[0],
      chapter: url_parts[1],
      page_number: url_parts[3] || '1',
    }
  end

  def url_parts
    @url_parts ||= url.sub(/^(https?:..)?[^\/]*[.]com\/(r\/)?/, '').split(?/)
  end

  def manga
    url_parts[0]
  end

  def chapter
    URI.decode(url_parts[1])
  end

  def page_number
    URI.decode(url_parts[3]) || '1' rescue 1
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

  def html_file(date=Date.today, count=1)
    @html_file ||= begin
                     name = format('%s-%03d.html', date, count)
                     File.exist?(name) ? html_file(date, count + 1) : name
                   end
  end

  def css
    <<-CSS
    <style type="text/css">
      img {
        width: 90%;
        border: solid 2px pink;
        margin: 3px;
      }
    </style>
    CSS
  end

  def img_tag(file)
    format('<img src="%s" alt="" />', file)
  end

  def save_html_file
    IO.write(html_file, [css, images.map(&method(:img_tag))].join('<br/>'))
  end

  def save_and_open_html_file
    save_html_file
    system 'open', html_file
  end

  def rip
    dest = folder || manga || default_folder
    cd_to File.join(ripper_path, dest)

    puts "Downloading Album: '%s'..." % dest

    next_link = url

    while next_link != nil
      ap next_link: next_link
      page_doc = doc_for_url next_link

      parsed_url = parse_url(next_link)
      filename = format('%s-%s.png', URI.decode(parsed_url[:chapter]), URI.decode(parsed_url[:page_number].gsub(/(\d+)/){|txt| format('%03d', txt) }))

      images.push filename

      if File.exist?(filename)
        puts 'Skip existing file "%s"...' % filename
        next_link = extract_next_link(page_doc)
        next
      end

      puts 'Saving "%s"...' % filename

      if image = page_doc.images.find{|img| img.dom_id == 'manga-page' }
        doc_for_url(image.src).save_as(filename)
      end

      next_link = extract_next_link(page_doc)
    end

    save_and_open_html_file
  end

  def extract_next_link(page_doc)
    if link_tag = page_doc.links.find{|a| a.text[/Next\s/] }
      link_tag.href
    end
  end

  def doc
    @doc ||= Mechanize.new.get(url)
  end

  def doc_for_url(url)
    ap doc_for_url: url
    docs[url] ||= Mechanize.new.get(url)
  end

  def docs
    @docs ||= {}.to_mash
  end

  def links
    @links ||= doc.links
  end

  def images
    @images ||= []
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

