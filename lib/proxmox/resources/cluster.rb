# frozen_string_literal: true

module Proxmox
  module Resources
    # Proxmox Cluster Class
    class Cluster
      def initialize(client)
        @client = client
      end

      def log(max: nil)
        params = {}
        params[:max] = max unless max.nil?

        @client.request(:get, "/cluster/log", params)
      end

      def nextid(vmid: nil)
        params = {}
        params[:vmid] = vmid unless vmid.nil?

        @client.request(:get, "/cluster/nextid", params)
      end

      def options
        @client.request(:get, "/cluster/options")
      end

      def resources
        @client.request(:get, "/cluster/resources")
      end

      def status
        @client.request(:get, "/cluster/status")
      end

      def tasks
        @client.request(:get, "/cluster/tasks")
      end

      # Getting all Nodes
      def nodes
        @client.request(:get, "/nodes")
      end
    end
  end
end
