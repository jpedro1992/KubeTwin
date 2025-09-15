module KUBETWIN
  class CPUFilter
    def self.run(nodes, req_cpu, req_mem)
      filtered_nodes = nodes.select { |entry| entry[:node].available_resources_cpu >= req_cpu }
      puts "[Scheduler] Starting CPUFilter...'"
      # puts "[Scheduler] CPUFilter filtered nodes: #{filtered_nodes.map { |n| n[:node].node_id }}"

      filtered_nodes
    end
  end
end

