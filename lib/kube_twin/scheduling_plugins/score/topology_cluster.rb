module KUBETWIN
  class TopologyClusterAggregate
    def self.run(nodes, _node_affinity)
      max_cpu = nodes.map { |entry| entry[:cluster].node_number * entry[:cluster].node_resources_cpu }.max.to_f
      max_mem = nodes.map { |entry| entry[:cluster].node_number * entry[:cluster].node_resources_memory }.max.to_f

      max_cpu = 1 if max_cpu.zero?
      max_mem = 1 if max_mem.zero?

      nodes.map do |entry|
        cluster = entry[:cluster]

        aggregate_cpu = cluster.node_number * cluster.node_resources_cpu
        aggregate_mem = cluster.node_number * cluster.node_resources_memory

        cpu_score = (aggregate_cpu / max_cpu) * 100
        mem_score = (aggregate_mem / max_mem) * 100
        combined_score = (cpu_score + mem_score) / 2.0

        puts "[Scheduler] TopologyClusterAggregate: Cluster #{cluster.name}, Nodes: #{cluster.node_number}, AggregateCPU: #{aggregate_cpu}, AggregateMem: #{aggregate_mem}, Score: #{combined_score.round(2)}"

        { node: entry[:node], score: combined_score }
      end
    end
  end
end
