require_relative '../../../kube_twin/latency_manager'

module KUBETWIN
  class DiktyoScoring

    def self.run(filtered_nodes, nodes, _node_affinity = nil)
      puts "[Scheduler] Starting Diktyo plugin...'"

      existing_pods = []
      existing_pods = build_existing_pods(nodes)
      # existing_pods_collect = collect_existing_pods(nodes)
      # puts "[Scheduler] Existing pods: #{existing_pods_collect}"

      scores = filtered_nodes.map do |entry|
        node    = entry[:node]
        cluster = entry[:cluster]
        pod_sel = entry[:pod_to_deploy_selector]
        dependencies = entry[:pod_dependencies]
        latency_manager = entry[:latency_manager]

        if cluster.nil? || pod_sel.nil?
          puts "[Scheduler] Node #{node.node_id} skipped (missing cluster or selector), giving max score to normalize after"
          { node: node, score: Float::INFINITY}
        else
          # puts "[Scheduler] Pod Dependencies #{dependencies}"

          # Calculate total latency
          total_latency = 0.0
          dependencies.each do |name, d|
            # puts "[Scheduler] Evaluating dependency '#{name}' for node '#{node.node_id}'...'"

            # check that src is equal to pod_sel
            next unless pod_sel == d[:src]

            # calculate latency between src and dst for all pods in existing pods
            # src will always be the node
            # dst will be the cluster location of the pod retrieved from existing pods
            existing_pods.each do |pod|

              # check that selector is equal to d[:dst]
              next unless pod[:selector] == d[:dst]

              dst_cluster = pod[:cluster]
              latency = latency_manager.sample_latency_between(cluster.location_id, dst_cluster.location_id)
              total_latency += latency
            end
          end
          # puts "[Scheduler] Diktyo: Node #{entry[:node].node_id} score: #{total_latency.round(2)}"
          { node: node, score: total_latency }
        end
      end

      # Normalize scores between 0–100 (invert so lower latency = higher normalized score)
      raw_scores = scores.map { |s| s[:score] }.reject { |s| s.infinite? || s.nan? }
      if raw_scores.empty?
        puts "[Scheduler] No valid scores to normalize"
        return scores
      end

      min_score = raw_scores.min
      max_score = raw_scores.max
      range = max_score - min_score > 0 ? max_score - min_score : 1.0

      normalized = scores.map do |s|
        if s[:score].infinite? || s[:score].nan?
          { node: s[:node], score: 0 }
        else
          norm = ((s[:score] - min_score) / range.to_f) * 100.0
          inv  = 100.0 - norm
          { node: s[:node], score: inv }
        end
      end

      normalized
    end

    private_class_method

    def self.build_existing_pods(nodes)
      existing_pods = []
      nodes.each do |entry|
        node = entry[:node]
        cluster = entry[:cluster]
        deployed_pods = entry[:node].pod_name_list

        if deployed_pods.empty?
          puts "[Scheduler] Node #{node.node_id} in cluster #{cluster&.location_id || 'nil'} has no deployed pods"
          next
        end

        deployed_pods.each do |pod_name|
          # puts "[Scheduler] Checking pod entry: #{pod_name}"
          unless pod_name.is_a?(String)
            puts "[Scheduler] Pod name invalid, skipping"
            next
          end

          selector = extract_selector_from_name(pod_name)
          # puts "[Scheduler] Extracted selector '#{selector}' from pod name '#{pod_name}'"

          existing_pods << { node: node, cluster: cluster, selector: selector }
        end
      end
      puts "[Scheduler] Total existing pods gathered: #{existing_pods.size}"
      existing_pods
    end

    def self.extract_selector_from_name(pod_name)
      pod_name.sub(/_\d+$/, '')
    end
  end
end



