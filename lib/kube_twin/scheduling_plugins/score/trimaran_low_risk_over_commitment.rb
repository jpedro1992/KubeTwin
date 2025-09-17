module KUBETWIN
  class LowRiskOverCommitment
    # Thresholds for resource overcommitment risk (can be adjusted)
    CPU_THRESHOLD = 0.8
    MEMORY_THRESHOLD = 0.8

    def self.run(filtered_nodes, _nodes, _node_affinity)
      puts "[Scheduler] Starting LowRiskOverCommitment plugin...'"

      filtered_nodes.map do |entry|
        # puts "[Scheduler] Node #{entry[:node].node_id} capacity: #{entry[:node].capacity_cpu}, requested: #{entry[:node].requested_cpu}, available: #{entry[:node].available_resources_cpu}"
        # puts "[Scheduler] Node #{entry[:node].node_id} capacity: #{entry[:node].capacity_memory}, requested: #{entry[:node].requested_memory}, available: #{entry[:node].available_resources_memory}"

        # Calculate requested-to-allocatable ratios
        # cpu_ratio = (entry[:node].requested_cpu.to_f / (entry[:node].available_resources_cpu.to_f + entry[:node].requested_cpu.to_f))
        # mem_ratio = (entry[:node].requested_memory.to_f / (entry[:node].available_resources_memory.to_f + entry[:node].requested_memory.to_f))

        cpu_ratio = entry[:node].requested_cpu.to_f / entry[:node].capacity_cpu.to_f
        mem_ratio = entry[:node].requested_memory.to_f / entry[:node].capacity_memory.to_f

        # puts "[Scheduler] LowRiskOverCommitment: Node #{entry[:node].node_id} cpu_requested: #{entry[:node].requested_cpu.to_f}, mem_requested: #{entry[:node].requested_memory.to_f}}"
        # puts "[Scheduler] LowRiskOverCommitment: Node #{entry[:node].node_id} cpu_ratio: #{cpu_ratio.round(2)}, mem_ratio: #{mem_ratio.round(2)}}"

        # Clamp ratios to max 1.0
        cpu_ratio = [cpu_ratio, 1.0].min
        mem_ratio = [mem_ratio, 1.0].min

        # puts "[Scheduler] LowRiskOverCommitment: Node #{entry[:node].node_id} cpu_ratio: #{cpu_ratio.round(2)}, mem_ratio: #{mem_ratio.round(2)}}"

        # Calculate score components inverted so lower ratios score higher
        # cpu_score = cpu_ratio < CPU_THRESHOLD ? 100 : 100 * (1 - (cpu_ratio - CPU_THRESHOLD) / (1.0 - CPU_THRESHOLD))
        # mem_score = mem_ratio < MEMORY_THRESHOLD ? 100 : 100 * (1 - (mem_ratio - MEMORY_THRESHOLD) / (1.0 - MEMORY_THRESHOLD))

        cpu_score = if cpu_ratio <= CPU_THRESHOLD
                      # Smooth score below threshold (more free → slightly lower score)
                      80 + 20 * (cpu_ratio / CPU_THRESHOLD)
                    else
                      # Linear penalty above threshold
                      100 * (1 - (cpu__ratio - CPU_THRESHOLD) / (1.0 - CPU_THRESHOLD))
                    end

        mem_score = if mem_ratio <= MEMORY_THRESHOLD
                      # Smooth score below threshold
                      80 + 20 * (mem_ratio / MEMORY_THRESHOLD)
                    else
                      # Linear penalty above threshold
                      100 * (1 - (mem_ratio - MEMORY_THRESHOLD) / (1.0 - MEMORY_THRESHOLD))
                    end

        # Clamp both scores to 0..100
        cpu_score = [[cpu_score, 0].max, 100].min
        mem_score = [[mem_score, 0].max, 100].min

        # average score
        combined_score = (cpu_score + mem_score) / 2.0

        # puts "[Scheduler] LowRiskOverCommitment: Node #{entry[:node].node_id} cpu_score: #{cpu_score.round(2)}, mem_score: #{mem_score.round(2)}, score: #{combined_score.round(2)}"

        { node: entry[:node], score: combined_score }
      end
    end
  end
end
