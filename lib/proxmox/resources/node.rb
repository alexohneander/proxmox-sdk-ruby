# frozen_string_literal: true

module Proxmox
  module Resources
    # Proxmox Node Class
    class Node
      def initialize(client, node_name)
        @client = client
        @node   = node_name
      end

      # Getting status of the Node
      def status
        @client.request(:get, "/nodes/#{@node}/status")
      end

      # Getting a list of updates for the Node
      def updates
        @client.request(:get, "/nodes/#{@node}/apt/update")
      end

      # Creating Resources
      def create_vm(params)
        @client.request(:post, "/nodes/#{@node}/qemu", {}, params)
      end
    end
  end
end
