# -*- coding: utf-8

require 'rubygems'
require 'bundler/setup'
require 'kconv'
require 'rack'
require 'sinatra/base'
require 'uri'

module Mail2www
  module Helpers
    include Rack::Utils
    alias_method :h, :escape_html
    alias_method :escape, :escape
    alias_method :escape_path, :escape_path
    alias_method :q, :build_query

    def append_slash(url)
      if url.include?('?')
        path, q, query = url.rpartition('?')
        path += '/' unless path.end_with?('/')
        url = path + q + query
      else
        url += '/' unless url.end_with?('/')
      end
      url
    end

    def get_from(mail)
      mail.from_addrs.join(',').encode('utf-8').scrub
    rescue Encoding::UndefinedConversionError
      "'From' contains invalid characters"
    end

    def get_to(mail)
      mail.to_addrs.join(',').encode('utf-8').scrub
    rescue Encoding::UndefinedConversionError
      "'To' contains invalid characters"
    end

    def get_cc(mail)
      mail.cc_addrs.join(',').encode('utf-8').scrub
    rescue Encoding::UndefinedConversionError
      "'Cc' contains invalid characters"
    end

    def get_addresses(mail, field_name)
      field = mail[field_name]
      return [] unless field

      field.element.addresses.map do |mailbox|
        {
          name: mailbox.display_name&.encode('utf-8')&.scrub,
          address: mailbox.address.encode('utf-8').scrub
        }
      end
    end

    def get_subject(mail)
      mail.subject ? mail.subject.encode('utf-8').scrub : '(no subject)'
    rescue Encoding::UndefinedConversionError
      '(no subject)'
    end

    def get_date(mail)
      (mail.date && mail.date.to_s) ||
        (mail.envelope_date && mail.envelope_date.to_s)
    end

    def get_header(mail)
      ['From: ' + (get_from(mail) || '(none)'),
       'To: ' + (get_to(mail) || '(none)'),
       'Cc: ' + (get_cc(mail) || '(none)'),
       'Subject: ' + get_subject(mail),
       'Date: ' + (get_date(mail) || '(none)')
      ].join("\n")
    end

    def body_text(message)
      raw_text = message.body.decoded

      if message.content_type
        charset = message.content_type_parameters['charset']
      end

      encoding =
        begin
          Encoding.find(charset) if charset
        rescue ArgumentError
          nil
        end || Kconv.guess(raw_text) || Encoding.UTF_8

      raw_text.force_encoding(encoding).encode('utf-8', invalid: :replace, undef: :replace)
    end

    def get_body(message)
      text_part = message.text_part
      html_part = message.html_part

      unless message.multipart?
        text_part ||= message if message.mime_type.nil? || message.mime_type == 'text/plain'
        html_part ||= message if message.mime_type == 'text/html'
      end

      {
        text: text_part && body_text(text_part),
        html: html_part && body_text(html_part)
      }
    end

    def render_mail_body(mail)
      body = get_body(mail).fetch(:text) || ''
      urls = URI.extract(body, %w(http https))
      surround_urls_with_a_tag(body, urls)
    end

    def surround_urls_with_a_tag(text, urls)
      result = ''
      urls.each do |url|
        pre, post = text.split(url, 2)
        # The not URL parts are escaped here.
        result += h(pre) + "<a href=\"#{h(url)}\" rel=noreferrer>#{h(url)}</a>"
        text = post
      end
      result + h(text)
    end

    def spam?(mail)
      spam = [*mail.header['X-Spam']]
      spam.any? {|v| v.value.upcase == 'YES' }
    end

    def virus_detected?(mail)
      virus = [*mail.header['X-Virus']]
      return if virus.empty?

      virus.map(&:value).join(', ')
    end
  end
end
