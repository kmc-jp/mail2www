# frozen_string_literal: true
# encoding: utf-8

require 'bundler/setup'
require 'json'
require 'mail'
require 'net/smtp'
require 'securerandom'
require 'sinatra/base'
require 'sinatra/config_file'
require 'time'

require_relative 'helpers'

module Mail2www
  # JSON API for the mail2www React application.
  class App < Sinatra::Base
    helpers Mail2www::Helpers
    register Sinatra::ConfigFile

    SAFE_ATTACHMENT_CONTENT_TYPES = %w[application/pdf image/jpeg image/png].freeze

    set :root, File.expand_path('..', __dir__)
    config_file 'config/mail2www.yml'

    configure :development do
      require 'sinatra/reloader'
      register Sinatra::Reloader
    end

    set :protection, except: :path_traversal
    set :show_exceptions, false

    before '/api/*' do
      content_type :json
    end

    error Sinatra::NotFound do
      json_error(404, env['sinatra.error']&.message || 'Not found')
    end

    error do
      error = env['sinatra.error']
      warn error.full_message if settings.development?
      json_error(500, 'Internal server error')
    end

    get '/api' do
      content_type :json
      json('OK')
    end

    get '/api/config' do
      json(
        title: settings.title,
        folders: settings.folders,
        ruby_version: RUBY_VERSION
      )
    end

    get '/api/folders/:folder/messages' do |folder|
      validate_folder!(folder)
      page = integer_param('page', default: 0, minimum: 0)
      per_page = integer_param('per_page', minimum: 1, maximum: 100)

      files = mail_numbers(folder)
      pages = (files.size.to_f / per_page).ceil
      page = 0 unless pages.positive? && page.between?(0, pages - 1)
      selected = files.slice(page * per_page, per_page) || []

      messages = selected.map do |number|
        mail = read_mail(folder, number)
        date = parse_mail_date(mail)
        {
          number: number,
          from: get_from(mail),
          date: date&.iso8601,
          subject: get_subject(mail)
        }
      end

      json(folder: folder, page: page, per_page: per_page, pages: pages,
           total: files.size, messages: messages)
    end

    get '/api/folders/:folder/messages/:mailnum' do |folder, mailnum|
      validate_folder!(folder)
      validate_mailnum!(mailnum)
      mail = read_mail(folder, mailnum)

      json(
        folder: folder,
        number: mailnum,
        headers: {
          from: get_addresses(mail, :from),
          to: get_addresses(mail, :to),
          cc: get_addresses(mail, :cc),
          subject: get_subject(mail),
          date: parse_mail_date(mail)&.iso8601
        },
        body: get_body(mail),
        spam: spam?(mail),
        virus: virus_detected?(mail),
        remote_user: remote_user,
        attachments: mail.attachments.map do |attachment|
          { filename: attachment.filename, content_type: attachment.mime_type }
        end
      )
    end

    get '/api/folders/:folder/messages/:mailnum/source' do |folder, mailnum|
      validate_folder!(folder)
      validate_mailnum!(mailnum)
      message = read_raw_mail(folder, mailnum)

      if truthy_param?('download')
        content_type 'message/rfc822'
        attachment "#{folder}-#{mailnum}.eml"
        message.sub(/\AFrom .*?\n/, '')
      else
        json(source: message.force_encoding('utf-8').scrub { |bytes| "<#{bytes.unpack1('H*')}>" })
      end
    end

    get '/api/folders/:folder/messages/:mailnum/attachments/:filename' do |folder, mailnum, filename|
      validate_folder!(folder)
      validate_mailnum!(mailnum)
      file = read_mail(folder, mailnum).attachments.find { |item| item.filename == filename }
      halt 404, json(error: 'Attachment not found') unless file

      if SAFE_ATTACHMENT_CONTENT_TYPES.include?(file.mime_type)
        content_type file.mime_type
      else
        content_type 'application/octet-stream'
        attachment file.filename
      end
      headers 'X-Content-Type-Options' => 'nosniff'
      file.decoded
    end

    post '/api/folders/:folder/messages/:mailnum/forward' do |folder, mailnum|
      validate_folder!(folder)
      validate_mailnum!(mailnum)
      payload = request.body.read
      payload = payload.empty? ? {} : JSON.parse(payload)
      to = payload.fetch('to')
      forward_mail(folder, mailnum, to: to)
      status 204
      body ''
    rescue JSON::ParserError, KeyError
      json_error(400, 'A JSON body containing "to" is required')
    rescue ArgumentError => e
      json_error(422, e.message)
    end

    private

    def json(value)
      JSON.generate(value)
    end

    def json_error(status_code, message)
      content_type :json
      halt status_code, json(error: message)
    end

    def integer_param(name, default: nil, minimum:, maximum: nil)
      value = params[name] ? Integer(params[name], 10) : default
      raise ArgumentError if value.nil?
      raise ArgumentError if value < minimum || (maximum && value > maximum)
      value
    rescue ArgumentError
      json_error(400, "#{name} must be an integer between #{minimum} and #{maximum || 'infinity'}")
    end

    def truthy_param?(name)
      %w[1 true yes].include?(params.fetch(name, '').downcase)
    end

    def validate_folder!(folder)
      json_error(404, 'Folder not found') if folder.start_with?('.') || folder.include?('/')
    end

    def validate_mailnum!(mailnum)
      json_error(404, 'Mail not found') unless /\A[1-9]\d*\z/.match?(mailnum)
    end

    def mail_numbers(folder)
      path = File.join(settings.mail_dir, folder)
      json_error(404, 'Folder not found') unless File.directory?(path)
      Dir.children(path).filter_map { |name| name if /\A[1-9]\d*\z/.match?(name) }
         .sort_by(&:to_i).reverse
    end

    def mail_path(folder, mailnum)
      File.join(settings.mail_dir, folder, mailnum.to_s)
    end

    def read_mail(folder, mailnum)
      raw = read_raw_mail(folder, mailnum)
      utf8 = raw.dup.force_encoding(Encoding::UTF_8)
      Mail.read_from_string(utf8.valid_encoding? ? utf8 : raw)
    end

    def read_raw_mail(folder, mailnum)
      IO.binread(mail_path(folder, mailnum))
    rescue Errno::ENOENT, Errno::EISDIR
      json_error(404, 'Mail not found')
    end

    def parse_mail_date(mail)
      value = get_date(mail)
      Time.parse(value) if value
    rescue ArgumentError
      nil
    end

    def generate_message_id(mailname)
      "<#{Time.now.strftime('%Y%m%d%H%M%S')}.#{SecureRandom.alphanumeric(16)}@#{mailname}>"
    end

    def forward_mail(folder, mailnum, to:)
      validate_local_part!(to)
      mailname = settings.mailname
      recipient = "#{to}@#{mailname}"
      bounce_to = settings.bounce_to
      bounce_to = bounce_to.call(recipient) if bounce_to.respond_to?(:call)
      message = read_raw_mail(folder, mailnum).sub(/\AFrom .*?\n/, '')
      fields = {
        'List-Id' => "<#{folder}.mail2www.#{mailname}>",
        'Resent-From' => recipient,
        'Resent-To' => recipient,
        'Resent-Date' => Time.now.rfc2822,
        'Resent-Message-ID' => generate_message_id(mailname)
      }
      message.prepend(fields.map { |name, value| "#{name}: #{value}\r\n" }.join)
      Net::SMTP.start(settings.smtp_server) do |smtp|
        smtp.send_message(message, bounce_to, recipient)
      end
    end

    def validate_local_part!(local_part)
      raise ArgumentError, 'Invalid local-part' unless local_part.is_a?(String) && /\A[a-zA-Z0-9-]+\z/.match?(local_part)
      local_part
    end

    def remote_user
      request.env['REMOTE_USER'] || request.env['HTTP_X_FORWARDED_USER']
    end
  end
end
