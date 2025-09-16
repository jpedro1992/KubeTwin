module KUBETWIN
  class CostAware
    # Default configuration
    DEFAULT_CONFIG = {
      weight_cpu: 1.0,   # Weight for CPU cost
      weight_mem: 1.0,   # Weight for memory cost
    }

    def self.run(nodes, node_affinity, opts = {})
      opts = {} unless opts.is_a?(Hash)
      weight_cpu = opts.fetch(:weight_cpu, DEFAULT_CONFIG[:weight_cpu])
      weight_mem = opts.fetch(:weight_mem, DEFAULT_CONFIG[:weight_mem])

      puts "[Scheduler] Starting CostAware plugin ..."

      result = nodes.map do |entry|
        # Compute CPU and Memory Cost for node
        cpu_cost = entry[:req_cpu] * entry[:cpu_hourly_cost]
        mem_cost = entry[:req_mem] * (entry[:mem_hourly_cost])

        # Weighted sum
        combined_score = (weight_cpu * cpu_cost) + (weight_mem * mem_cost)

        # puts "[Scheduler] CostAware: Node #{node.node_id} - CPU_hourly_cost=#{entry[:cpu_hourly_cost]}, MEM_hourly_cost=#{entry[:mem_hourly_cost]}}"
        # puts "[Scheduler] CostAware: Node #{node.node_id} - CPU_req =#{entry[:req_cpu]}, CPU_cost=#{cpu_cost}, MEM_req=#{entry[:req_mem]}, MEM_cost=#{mem_cost}, combined=#{combined_score}}"
        { node: entry[:node], combined_score: combined_score}
      end

      # Normalize scores to 0-100 (lower cost → higher score)
      min = result.map { |e| e[:combined_score] }.min
      max = result.map { |e| e[:combined_score] }.max
      range = max - min

      normalizedResult = result.map do |e|
        score = (range == 0) ? 100.0 : ((max - e[:combined_score]) / range.to_f) * 100

        # puts "[Scheduler] CostAware: Node #{e[:node].node_id} Score=#{e[:combined_score]} normScore=#{score}"

        { node: e[:node], score: score }
      end

      normalizedResult
    end
  end
end