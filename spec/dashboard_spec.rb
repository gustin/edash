require File.dirname(__FILE__) + '/spec_helper'

describe Dashboard::Server do
  include Rack::Test::Methods
  include Webrat::Methods
  include Webrat::Matchers

  after(:each) do
    `rm -f #{File.dirname(__FILE__)}/../dashboard-test.pstore`
    raise "Cannot remove test file!" if $? != 0
  end

  def app
    @app ||= Dashboard::Server
  end

  it "responds to /" do
    visit'/'
    last_response.body.should match(/Dashboard/)
  end

  it "responds to a blank url too" do
    visit ''
    last_response.body.should match(/Dashboard/)
  end

  context "posting build update" do
    before(:each) do
      Dashboard::Client.stub!(:send_message)
    end

    def do_post(status)
      post 'build', :project => 'moo', :status => status
      visit '/'
    end

    it "tags passing builds green" do
      do_post('pass')
      last_response.body.should have_selector('a.pass') do |div|
        div.should contain('moo')
      end
    end

    it "tags failing builds red" do
      do_post('fail')
      last_response.body.should have_selector('a.fail') do |div|
        div.should contain(/moo/)
      end
    end

    it "does not have an image" do
      do_post('fail')
      last_response.body.should_not have_selector('div.project img')
    end

    it "tags building grey with a loading image" do
      do_post('building')
      last_response.body.should have_selector('a.building')
      last_response.body.should have_selector('div.project img[src*=loading]')
    end
    context "with an author" do

      def do_post(author = "")
        post 'build', :project => 'moo', :status => 'fail', :author => author
        visit '/'
      end

      it "shows the author gravator for the last commit" do
        do_post('Chris Parsons <chris@example.com>')
        last_response.body.should have_selector('a.fail')
        last_response.body.should have_selector('div.project img[src*="9655f78d38f380d17931f8dd9a227b9f"]')
      end

      it "replaces spaces with plusses in the email addresses" do
        do_post('C P <dev sermoa tristanharris@edendevelopment.co.uk>')
        last_response.body.should have_selector('div.project img[src*="fecb482a5c1d13c869027b5dac71da00"]')
      end
      
      it "posts to a websocket" do
        Dashboard::Client.should_receive(:send_message).with(anything, /"status":"fail"/)
        do_post
      end
    end
  end
end
