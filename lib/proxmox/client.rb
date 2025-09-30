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
      response = perform_http_call(method, path, params, body)

      ensure_success!(response)
      extract_data(response)
    end

    private

    def perform_http_call(method, path, params, body)
      http.send(method) do |req|
        set_url(req, path)
        add_cookie_header(req)
        set_csrf_header(req, method)
        set_query_params(req, method, params)
        set_body(req, body)
      end
    end

    def set_url(req, path)
      req.url "/api2/json#{path}"
    end

    def add_cookie_header(req)
      req.headers["Cookie"] = "PVEAuthCookie=#{ticket}"
    end

    def set_csrf_header(req, method)
      return unless %i[post put delete].include?(method)

      req.headers["CSRFPreventionToken"] = csrf_token
    end

    def set_query_params(req, method, params)
      req.params.update(params) if method == :get && params.any?
    end

    def set_body(req, body)
      req.body = body.to_json if body
    end

    def ensure_success!(response)
      raise ApiError, response.body unless response.success?
    end

    def extract_data(response)
      JSON.parse(response.body)["data"]
    end

    def http
      @http ||= Faraday.new(url: @base_url, ssl: { verify: @verify_ssl }) do |f|
        f.request :url_encoded
        f.adapter Faraday.default_adapter
      end
    end
  end
end
