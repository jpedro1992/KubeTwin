module KUBETWIN
  class ResourceAvailabilityScore
    def self.run(filtered_nodes, _nodes, _node_affinity)
      w_cpu = 0.75
      w_mem = 0.25
      puts "[Scheduler] Starting ResourceAvailabilityScore plugin... w_cpu #{w_cpu} and w_mem #{w_mem}'"
      # Score nodes by available CPU and Memory combined (weighted average)
      max_cpu = filtered_nodes.map { |n| n[:node].available_resources_cpu }.max.to_f
      max_mem = filtered_nodes.map { |n| n[:node].available_resources_memory }.max.to_f

      max_cpu = 1 if max_cpu == 0
      max_mem = 1 if max_mem == 0

      # puts "[Scheduler] ResourceAvailabilityScore: max_CPU: #{max_cpu}, max_MEM: #{max_mem}"

      result = filtered_nodes.map do |entry|
        cpu_score = (entry[:node].available_resources_cpu.to_f / max_cpu) * 100
        mem_score = (entry[:node].available_resources_memory.to_f / max_mem) * 100

        # weighted average (equal weight)
        combined_score = (w_cpu * cpu_score + w_mem * mem_score) / 2.0
        # puts "[Scheduler] Node #{entry[:node].node_id} score: #{combined_score.round(2)}"

        { node: entry[:node], score: combined_score }
      end

      result
    end
  end
end






