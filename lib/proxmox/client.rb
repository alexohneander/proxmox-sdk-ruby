# frozen_string_literal: true

require "faraday"
require "json"
require "time"

module Proxmox
  # Proxmox SDK Http Client
  class Client
    # Konstanten für die Gültigkeit des Tokens
    # Proxmox Tickets sind standardmäßig 2 Stunden (7200 Sekunden) gültig.
    TOKEN_VALIDITY_SECONDS = 7200
    # Wir erneuern den Token 5 Minuten (300 Sekunden) vor Ablauf.
    RENEWAL_BUFFER_SECONDS = 300

    attr_reader :ticket, :csrf_token, :base_url

    def initialize(base_url:, username:, password:, realm: "pam", ignore_ssl: false)
      @base_url = base_url
      @verify_ssl = !ignore_ssl

      # Anmeldedaten für die automatische Erneuerung speichern
      @username = username
      @password = password
      @realm = realm

      # Initiales Login
      login
    end

    def login
      resp = http.post("/api2/json/access/ticket",
                       { username: "#{@username}@#{@realm}", password: @password })

      raise "Login failed: #{resp.body}" unless resp.success?

      data = JSON.parse(resp.body)["data"]
      @ticket = data["ticket"]
      @csrf_token = data["CSRFPreventionToken"]
      # Zeitstempel der Ticketerstellung speichern
      @ticket_creation_time = Time.now
    end

    def request(method, path, params = {}, body = nil)
      # Vor jeder Anfrage die Gültigkeit des Tokens prüfen und ggf. erneuern
      ensure_token_validity

      response = perform_http_call(method, path, params, body)

      ensure_success!(response)
      extract_data(response)
    end

    private

    # NEUE METHODE: Stellt sicher, dass der Token gültig ist
    def ensure_token_validity
      login if token_expired?
    end

    # NEUE METHODE: Prüft, ob der Token abgelaufen ist oder bald abläuft
    def token_expired?
      # Wenn noch kein Ticket erstellt wurde, nicht als abgelaufen betrachten
      return false if @ticket_creation_time.nil?

      # Berechne die Ablaufzeit (Erstellungszeit + Gültigkeit - Puffer)
      renewal_time = @ticket_creation_time + TOKEN_VALIDITY_SECONDS - RENEWAL_BUFFER_SECONDS

      # Ist die aktuelle Zeit nach der errechneten Erneuerungszeit?
      Time.now > renewal_time
    end

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
      # Optional: Wenn ein 401 (Unauthorized) Fehler kommt, könnte man hier auch ein erneutes Login erzwingen.
      # if response.status == 401
      #   login
      #   # Hier könnte man die Anfrage wiederholen.
      # end
      raise "ApiError: #{response.body}" unless response.success?
    end

    def extract_data(response)
      # Sicherstellen, dass der Body nicht leer ist, bevor geparst wird
      return nil if response.body.nil? || response.body.empty?

      JSON.parse(response.body)["data"]
    end

    def http
      @http ||= Faraday.new(url: @base_url, ssl: { verify: @verify_ssl }) do |f|
        f.request :url_encoded
        f.adapter Faraday.default_adapter
      end
    end
  end

  # Eigene Fehlerklasse (optional, aber guter Stil)
  class ApiError < StandardError; end
end
