# frozen_string_literal: true

require "faraday"

module Proxmox
  # Proxmox SDK Http Client
  class Client
    attr_reader :ticket, :csrf_token, :base_url

    def initialize(base_url:, username:, password:, realm: "pam", ignore_ssl: false)
      @base_url = base_url
      @verify_ssl = !ignore_ssl
      login(username, password, realm)
    end

    def login(user, pass, realm)
      resp = http.post("/api2/json/access/ticket",
                       { username: "#{user}@#{realm}", password: pass })
      data = JSON.parse(resp.body)["data"]
      @ticket     = data["ticket"]
      @csrf_token = data["CSRFPreventionToken"]
    end

    def request(method, path, params = {}, body = nil)
      response = http.send(method) do |req|
        req.url "/api2/json#{path}"
        req.headers["Cookie"] = "PVEAuthCookie=#{ticket}"
        req.headers["CSRFPreventionToken"] = csrf_token if %i[post put delete].include?(method)
        req.params.update(params) if method == :get
        req.body = body.to_json if body
      end

      raise ApiError, response.body unless response.success?

      JSON.parse(response.body)["data"]
    end

    private

    def http
      @http ||= Faraday.new(url: @base_url, ssl: { verify: @verify_ssl }) do |f|
        f.request :url_encoded
        f.adapter Faraday.default_adapter
      end
    end
  end
end
