require 'rubygems'
require 'bundler/setup'

require 'spec_helper'
require_relative '../lib/config.example.rb'

module Mail2www
  describe Config do
    it "#mail_dir" do
      expect(subject[:mail_dir]).not_to be_nil
      expect(subject[:mail_dir]).to be_an_instance_of(String)
    end

    it "#folders" do
      expect(subject[:folders]).not_to be_nil
      expect(subject[:folders]).to be_an_instance_of(Array)
    end

    it "#title" do
      expect(subject[:title]).not_to be_nil
      expect(subject[:title]).to be_an_instance_of(String)
    end

    context "when the constructor receives a hash" do
      let (:hash) { {
          mail_dir: "new mail dir",
          folders: %w(folder1, folder2),
          title: "new title"
        } }

      subject { Mail2www::Config.new(hash) }

      it "#mail_dir" do
        expect(subject[:mail_dir]).to eq(hash[:mail_dir])
      end

      it "#folders" do
        expect(subject[:folders]).to eq(hash[:folders])
      end

      it "#title" do
        expect(subject[:title]).to eq(hash[:title])
      end

    end
  end
end
