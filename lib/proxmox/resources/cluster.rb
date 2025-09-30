# frozen_string_literal: true

module Proxmox
  module Resources
    # Proxmox Cluster Class
    class Cluster
      def initialize(client)
        @client = client
      end

      # Getting all Nodes
      def nodes
        @client.request(:get, "/nodes")
      end
    end
  end
end
