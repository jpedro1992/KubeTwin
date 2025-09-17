# Priority param "Most": nodes with most allocatable resources score highest
module KUBETWIN
  class NodeResourcesMostAllocatable
    def self.run(filtered_nodes, _nodes, _node_affinity)
      puts "[Scheduler] Starting NodeResourcesMostAllocatable plugin...'"

      max_cpu = filtered_nodes.map { |n| n[:node].available_resources_cpu.to_f }.max
      max_mem = filtered_nodes.map { |n| n[:node].available_resources_memory.to_f }.max

      max_cpu = 1 if max_cpu.nil? || max_cpu.zero?
      max_mem = 1 if max_mem.nil? || max_mem.zero?

      # puts "[Scheduler] NodeResourcesMostAllocatable: max_CPU: #{max_cpu}, max_MEM: #{max_mem}"

      filtered_nodes.map do |entry|
        # puts "[Scheduler] Node #{entry[:node].node_id} capacity: #{entry[:node].capacity_cpu}, requested: #{entry[:node].requested_cpu}, available: #{entry[:node].available_resources_cpu}"
        # puts "[Scheduler] Node #{entry[:node].node_id} capacity: #{entry[:node].capacity_memory}, requested: #{entry[:node].requested_memory}, available: #{entry[:node].available_resources_memory}"

        cpu_alloc = entry[:node].available_resources_cpu.to_f
        mem_alloc = entry[:node].available_resources_memory.to_f

        # Direct scoring: more allocatable resource → higher score
        cpu_score = (cpu_alloc / max_cpu) * 100
        mem_score = (mem_alloc / max_mem) * 100

        combined_score = (cpu_score + mem_score) / 2.0

        # puts "[Scheduler] NodeResourcesMostAllocatable: Node #{entry[:node].node_id} score: #{combined_score.round(2)}"

        { node: entry[:node], score: combined_score }
      end
    end
  end
end