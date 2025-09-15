module KUBETWIN
  class LowRiskOverCommitment
    # Thresholds for resource overcommitment risk (can be adjusted)
    CPU_THRESHOLD = 0.8
    MEMORY_THRESHOLD = 0.8

    def self.run(nodes, _node_affinity)
      puts "[Scheduler] Starting LowRiskOverCommitment...'"

      nodes.map do |entry|
        node = entry[:node]

        # Calculate requested-to-allocatable ratios
        cpu_ratio = node.requested_resources[:cpu].to_f / (entry[:available_resources_cpu] + node.requested_resources[:cpu])
        mem_ratio = node.requested_resources[:memory].to_f / (node.available_resources_memory + node.requested_resources[:memory])

        # Clamp ratios to max 1.0
        cpu_ratio = [cpu_ratio, 1.0].min
        mem_ratio = [mem_ratio, 1.0].min

        # Calculate score components inverted so lower ratios score higher
        cpu_score = cpu_ratio < CPU_THRESHOLD ? 100 : 100 * (1 - (cpu_ratio - CPU_THRESHOLD) / (1.0 - CPU_THRESHOLD))
        mem_score = mem_ratio < MEMORY_THRESHOLD ? 100 : 100 * (1 - (mem_ratio - MEMORY_THRESHOLD) / (1.0 - MEMORY_THRESHOLD))

        # average score
        combined_score = (cpu_score + mem_score) / 2.0

        # puts "[Scheduler] LowRiskOverCommitment: Node #{node.node_id} cpu_score: #{cpu_score.round(2)}, mem_score: #{mem_score.round(2)}, score: #{combined_score.round(2)}"

        { node: node, score: combined_score }
      end
    end
  end
end
