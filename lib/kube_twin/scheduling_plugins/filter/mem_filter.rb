module KUBETWIN
  class MEMFilter
    def self.run(nodes, req_cpu, req_mem)
      filtered_nodes = nodes.select { |entry| entry[:node].available_resources_memory >= req_mem }
      puts "[Scheduler] MEMFilter filtered nodes: #{filtered_nodes.map { |n| n[:node].node_id }}"

      filtered_nodes
    end
  end
end

