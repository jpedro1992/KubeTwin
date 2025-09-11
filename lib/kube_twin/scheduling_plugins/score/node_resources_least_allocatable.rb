module KUBETWIN
  # Scores nodes based on their allocatable CPU and memory resources
  # Priority param "Least": nodes with least allocatable resources score highest
  class NodeResourcesLeastAllocatable
    def self.run(nodes, _node_affinity)
      max_cpu = nodes.map { |n| n[:available_resources_cpu].to_f }.max
      max_mem = nodes.map { |n| n[:node].available_resources_memory.to_f }.max

      max_cpu = 1 if max_cpu.nil? || max_cpu.zero?
      max_mem = 1 if max_mem.nil? || max_mem.zero?

      nodes.map do |entry|
        cpu_alloc = entry[:available_resources_cpu].to_f
        mem_alloc = entry[:node].available_resources_memory.to_f

        # Inverted scoring: less allocatable resource → higher score
        cpu_score = ((max_cpu - cpu_alloc) / max_cpu) * 100
        mem_score = ((max_mem - mem_alloc) / max_mem) * 100

        combined_score = (cpu_score + mem_score) / 2.0

        puts "[Scheduler] NodeResourcesLeastAllocatable: Node #{entry[:node].node_id} score: #{combined_score.round(2)}"

        { node: entry[:node], score: combined_score }
      end
    end
  end
end
