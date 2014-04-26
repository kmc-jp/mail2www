# -*- coding: utf-8 -*-

require 'rubygems'
require 'bundler/setup'
require 'time'
require 'erb'
require 'mail'
require 'kconv'
require 'sinatra/base'

require_relative 'helpers'

module Mail2www
  class App < Sinatra::Base
    helpers Mail2www::Helpers

    set :views, "#{File.dirname(__FILE__)}/../views"
    set :public_folder, "#{File.dirname(__FILE__)}/../public"

    def initialize(config)
      @config = config
      super
    end

    get '/' do
      redirect to(append_slash(request.url)) if request.path_info.empty?

      @title = @config[:title]
      folder = params['f'] || @config[:folders][0]
      mailnum = params['m']
      page = params['p'].to_i

      if mailnum
        mail(folder, mailnum)
      else
        list(folder, page)
      end
    end

    # Stop annoying errors
    get '/favicon.ico' do
    end

    def list(folder, page)
      mails_path = File.join(@config[:mail_dir], folder)
      halt(404, 'Folder not found') unless File.directory?(mails_path)

      files = Dir.entries(mails_path).map! { |file| file.to_i }
        .sort.reject { |n| n == 0 }.reverse
      mails_per_page = @config[:mails_per_page]
      pages = files.size / mails_per_page
      pages += 1 if files.size % mails_per_page != 0
      page = 0 unless page.between?(0, pages - 1)

      files = files.slice(page * mails_per_page, mails_per_page)
      mails = files.map do |num|
        mail_path = File.join(mails_path, num.to_s)
        mail = Mail.read(mail_path)
        t = mail.date.nil? ? Time.now : Time.parse(mail.date.to_s)
        time = "#{t.month}/#{t.day} (#{how_old(t)})"

        [num.to_s, get_from(mail), time, mail.subject.toutf8]
      end

      vars = { folder: folder, pages: pages, page: page, mails: mails }
      erb :list, locals: vars
    end

    def mail(folder, mailnum)
      path = File.join(@config[:mail_dir], folder, mailnum)
      halt(404, 'File not found') unless File.file?(path)

      mail = Mail.read(path)
      subject = mail.subject.toutf8 || '(no subject)'

      @title += "(#{folder || '(none)'}) / #{subject || '(none)'}"
      vars = { folder: folder, subject: subject, mail: mail }
      erb :mail, locals: vars
    end
  end
end
