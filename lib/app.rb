# -*- coding: utf-8 -*-

require 'rubygems'
require 'bundler/setup'
require 'securerandom'
require 'time'
require 'erb'
require 'mail'
require 'sinatra/base'
require 'net/smtp'

require_relative 'helpers'
require_relative 'mail_extension'

module Mail2www
  class App < Sinatra::Base
    helpers Mail2www::Helpers

    configure :development do
      Bundler.require :development
      register Sinatra::Reloader
    end

    set :views, "#{File.dirname(__FILE__)}/../views"
    set :public_folder, "#{File.dirname(__FILE__)}/../public"
    set :protection, except: :path_traversal

    def initialize(config)
      @config = config
      @title = @config[:title]
      @config[:prefix] = ENV['SCRIPT_NAME'] unless
        ENV['SCRIPT_NAME'].nil? || ENV['SCRIPT_NAME'].empty?
      super
    end

    get '/' do
      redirect to(@config[:folders][0])
    end

    # Stop annoying errors
    get '/favicon.ico' do
    end

    SAFE_ATTACHMENT_CONTENT_TYPES = %w[
      application/pdf
      image/jpeg
      image/png
    ]

    get '/:folder/:mailnum/attachment/:filename' do |folder, mailnum, filename|
      mail = read_mail(folder, mailnum)
      file = find_attachment_by_name(mail, filename) or halt(404, 'Attachment not found')

      if SAFE_ATTACHMENT_CONTENT_TYPES.include?(file.mime_type)
        headers['Content-Type'] = file.mime_type
      else
        headers['Content-Type'] = 'application/octet-stream'
        headers['Content-Disposition'] = 'attachment'
      end
      headers['X-Content-Type-Options'] = 'nosniff'

      file.decoded
    end

    get '/:folder/:mailnum' do |folder, mailnum|
      mail(folder, mailnum)
    end

    get '/:folder/:mailnum/source' do |folder, mailnum|
      download = !params.fetch(:download, '').empty?
      mail_raw(folder, mailnum, download: download)
    end

    post '/:folder/:mailnum/forward' do |folder, mailnum|
      to = params.fetch(:to)
      forward_mail(folder, mailnum, to: to)

      redirect to("/#{folder}/#{mailnum}")
    end

    get '/:folder' do |folder|
      page = params['page'].to_i
      per_page = @config[:mails_per_page]
      per_page = params['pp'].to_i unless params['pp'].nil?
      list(folder, page, per_page)
    end

    private

    def find_attachment_by_name(mail, filename)
      mail.attachments.find do |attachment|
        attachment.filename == filename
      end
    end

    def list(folder, page, mails_per_page)
      mails_path = File.join(@config[:mail_dir], folder)
      halt(404, 'Folder not found') unless File.directory?(mails_path)

      files = Dir.entries(mails_path).map! { |file| file.to_i }
        .sort.reject { |n| n == 0 }.reverse
      pages = files.size / mails_per_page
      pages += 1 if files.size % mails_per_page != 0
      page = 0 unless page.between?(0, pages - 1)

      files = files.slice(page * mails_per_page, mails_per_page)
      mails = files.map do |num|
        mail_path = File.join(mails_path, num.to_s)
        mail = Mail.read(mail_path)
        t = Time.parse(get_date(mail)) || Time.now
        time = "#{t.month}/#{t.day} (#{how_old(t)})"

        [num.to_s, get_from(mail), time, get_subject(mail)]
      end

      vars = {
        folder: folder, pages: pages, page: page, mails: mails,
        mails_per_page: mails_per_page,
        custom_pp: mails_per_page != @config[:mails_per_page]
      }
      erb :list, locals: vars
    end

    def mail_path(folder, mailnum)
      File.join(@config[:mail_dir], folder, mailnum)
    end

    def read_mail(folder, mailnum)
      path = mail_path(folder, mailnum)
      s = IO.binread(path)
      s2 = s.clone
      s.force_encoding("utf-8")
      if s.valid_encoding?
        Mail.read_from_string(s)
      else
        Mail.read_from_string(s2)
      end
    rescue Errno::ENOENT
      halt 404, 'Mail not found'
    end

    def mail(folder, mailnum)
      mail = read_mail(folder, mailnum)

      @title += "(#{folder || '(none)'}) / #{get_subject(mail)}"
      vars = {
        folder: folder,
        mail: mail,
        mailnum: mailnum,
        remote_user: remote_user,
      }
      erb :mail, locals: vars
    end

    def mail_raw(folder, mailnum, download:)
      begin
        message = IO.binread(mail_path(folder, mailnum))
      rescue Errno::ENOENT
        halt 404, 'Mail not found'
      end

      if download
        content_type :eml
        attachment "#{folder}-#{mailnum}.eml"
        message.sub(/\AFrom .*?\n/, '')  # first line may contain envelope header
      else
        @title += "(#{folder || '(none)'}) / #{mailnum}"
        vars = {
          folder: folder,
          mailnum: mailnum,
          message: message.force_encoding('utf-8').scrub{|bs| "<#{bs.unpack1('H*')}>" },
        }
        erb :rawmail, locals: vars
      end
    end

    def generate_message_id(mailname)
      "<#{Time.now.strftime('%Y%m%d%H%M%S')}.#{SecureRandom.alphanumeric(16)}@#{mailname}>"
    end

    def forward_mail(folder, mailnum, to:)
      # Care should be taken not to modify any single byte in the message body.
      # Doing so will make cryptographically signed (DKIM) mails unverifiable.
      # TODO: It might be necessary to implement "From munging" for non-DKIM messages.

      validate_local_part!(to)
      mailname = @config.fetch(:mailname)
      to = "#{to}@#{mailname}"
      bounce_to = @config.fetch(:bounce_to)
      bounce_to = bounce_to.call(to) if bounce_to.respond_to?(:call)

      begin
        message = IO.read(mail_path(folder, mailnum)).sub(/\AFrom .*?\n/, '')  # first line may contain envelope header
      rescue Errno::ENOENT
        halt 404, 'Mail not found'
      end

      resent_fields = {
        'List-Id' => "<#{folder}.mail2www.#{mailname}>",
        'Resent-From' => to,
        'Resent-To' => to,
        'Resent-Date' => Time.now.rfc2822,
        'Resent-Message-ID' => generate_message_id(mailname),
      }
      message.prepend(resent_fields.map {|name, value| "#{name}: #{value}\r\n" }.join)

      smtp_envelope_from = bounce_to
      smtp_envelope_to = to
      Net::SMTP.start(@config.fetch(:smtp_server)) do |smtp|
        smtp.send_message(
          message,
          smtp_envelope_from,
          smtp_envelope_to,
        )
      end
    end

    def validate_local_part!(local_part)
      unless /\A[a-zA-Z0-9-]+\z/ =~ local_part
        fail 'Invalid local-part'
      end
      local_part
    end

    def remote_user
      request.env['REMOTE_USER'] || request.env['HTTP_X_FORWARDED_USER']
    end
  end
end
