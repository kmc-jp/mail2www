# -*- coding: utf-8

require 'rubygems'
require 'bundler/setup'
require 'kconv'
require 'sinatra/base'

module Mail2www
  module Helpers
    def get_addresses(mail, field_name)
      field = mail[field_name]
      return [] unless field&.element

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
      mail.date || mail.envelope_date
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
