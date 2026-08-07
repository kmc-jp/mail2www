require 'bundler/setup'

require_relative 'spec_helper'
require_relative '../lib/app'

describe 'config/mail2www.yml' do
  subject(:settings) do
    Class.new(Mail2www::App).tap do |app|
      app.config_file 'config/mail2www.example.yml'
    end.settings
  end

  it 'loads the mail archive settings through Sinatra::ConfigFile' do
    expect(settings.mail_dir).to be_a(String)
    expect(settings.folders).to be_an(Array)
  end

  it 'loads the SMTP settings through Sinatra::ConfigFile' do
    expect(settings.smtp_server).to be_a(String)
    expect(settings.mailname).to be_a(String)
    expect(settings.bounce_to).to be_a(String)
  end
end
