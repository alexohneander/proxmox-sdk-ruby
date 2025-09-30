# frozen_string_literal: true

module Proxmox
  module Resources
    module Clusters
      # Proxmox Cluster Acme class
      class Backup
        def initialize(client)
          @client = client
        end

        def all
          @client.request(:get, "/cluster/backup")
        end
      end
    end
  end
end
