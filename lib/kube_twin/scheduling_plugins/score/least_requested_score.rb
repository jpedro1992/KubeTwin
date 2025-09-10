module KUBETWIN
  class LeastRequestedScore
    def self.run(nodes, _node_affinity = nil)
      max_cpu = nodes.map { |n| n[:node].requested_resources[:cpu].to_f }.max
      max_mem = nodes.map { |n| n[:node].requested_resources[:memory].to_f }.max

      max_cpu = 1 if max_cpu.nil? || max_cpu.zero?
      max_mem = 1 if max_mem.nil? || max_mem.zero?

      scores = nodes.map do |entry|
        requested_cpu = entry[:node].requested_resources[:cpu].to_f
        requested_mem = entry[:node].requested_resources[:memory].to_f

        cpu_score = ((max_cpu - requested_cpu) / max_cpu) * 100
        mem_score = ((max_mem - requested_mem) / max_mem) * 100

        combined_score = (cpu_score + mem_score) / 2.0

        puts "[Scheduler] LeastRequestedScore: Node #{entry[:node].node_id} score: #{combined_score.round(2)}"

        { node: entry[:node], score: combined_score }
      end

      scores
    end
  end
end


