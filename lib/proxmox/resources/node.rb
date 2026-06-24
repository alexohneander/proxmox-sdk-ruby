# frozen_string_literal: true

module Proxmox
  module Resources
    # Proxmox Node Class
    class Node
      # Define the attributes we expect from the API
      STATS_ATTRIBUTES = %i[id cpu maxcpu mem maxmem uptime].freeze
      attr_reader :node, *STATS_ATTRIBUTES
      alias name node

      def initialize(client, name_or_data)
        @client = client
        if name_or_data.is_a?(Hash)
          @node = name_or_data["node"]
          @raw_status = name_or_data["status"]

          # Dynamically set known attributes to avoid boilerplate
          STATS_ATTRIBUTES.each do |attr|
            instance_variable_set("@#{attr}", name_or_data[attr.to_s])
          end
        else
          @node = name_or_data
        end
      end

      def inspect
        "#<Proxmox::Resources::Node name=#{@node} status=#{@raw_status}>"
      end

      def online?
        @raw_status == "online"
      end

      # Access the Cluster resource
      def cluster
        @client.cluster
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
