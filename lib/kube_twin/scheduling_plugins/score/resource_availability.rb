module KUBETWIN
  class ResourceAvailabilityScore
    def self.run(nodes, _node_affinity)
      puts "[Scheduler] Starting ResourceAvailabilityScore...'"
      # Score nodes by available CPU and Memory combined (weighted average)
      max_cpu = nodes.map { |n| n[:available_resources_cpu] }.max.to_f
      max_mem = nodes.map { |n| n[:available_resources_memory] }.max.to_f
      max_cpu = 1 if max_cpu == 0
      max_mem = 1 if max_mem == 0

      result = nodes.map do |entry|
        cpu_score = (entry[:available_resources_cpu].to_f / max_cpu) * 100
        mem_score = (entry[:available_resources_memory].to_f / max_mem) * 100
        # weighted average (equal weight)
        combined_score = (cpu_score + mem_score) / 2.0

        # puts "[Scheduler] ResourceAvailabilityScore: Node #{entry[:node].node_id} score: #{combined_score.round(2)}"

        { node: entry[:node], score: combined_score }
      end

      result
    end
  end
end






