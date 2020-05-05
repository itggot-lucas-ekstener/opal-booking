require 'sinatra'
require 'test/unit'
require 'capybara'
require 'capybara/dsl'
require 'selenium-webdriver'
require_relative 'app.rb'

class TestApp < Test::Unit::TestCase
    
    include Capybara
    include ::Capybara::DSL

    def setup
        Capybara.app = App
        Capybara.default_driver = :selenium_chrome
        Capybara.server = :webrick
    end

    def test_start
        visit '/'
        page.has_content?('Startsida')
        sleep 1
    end

    def test_register
        visit '/'
        sleep 1
        click_on('Login')
        sleep 1
        click_on('Register')
        sleep 1
        fill_in('name', with: 'test_user7')
        sleep 0.5
        fill_in('mail', with: 'tester7@flaskpost.se')
        sleep 0.5
        fill_in('password', with: 'test07')
        sleep 0.5
        fill_in('confirm_password', with: 'test07')
        sleep 0.5
        click_on('Register')
        sleep 1
        fill_in('username', with: 'test_user7')
        sleep 0.5
        fill_in('password', with: 'test07')
        sleep 1
        click_on('Log in')
        sleep 2
        click_on('Log out')
        sleep 2
    end
end