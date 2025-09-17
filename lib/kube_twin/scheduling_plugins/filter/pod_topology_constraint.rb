module KUBETWIN
  class PodTopologySpreadConstraint
    # config example
    DEFAULT_CONFIG = {
      maxSkew: 1,
      topologyKey: "location_id", # or "tier"
      whenUnsatisfiable: "DoNotSchedule",
    }

    def self.run(nodes, _node_affinity = nil, opts = {})
      opts = {} unless opts.is_a?(Hash)
      max_skew = opts.fetch(:maxSkew, DEFAULT_CONFIG[:maxSkew])
      topology_key = opts.fetch(:topologyKey, DEFAULT_CONFIG[:topologyKey])
      when_unsatisfiable = opts.fetch(:whenUnsatisfiable, DEFAULT_CONFIG[:whenUnsatisfiable])

      # Each node entry already carries the pod_to_deploy_selector
      selector = nodes.first[:pod_to_deploy_selector]

      if selector.nil?
        puts "[Scheduler] No pod_to_deploy_selector provided, skipping spread constraint"
        return nodes
      end

      puts "[Scheduler] Starting PodTopologySpreadConstraint plugin with configuration: maxSkew=#{max_skew}, topologyKey=#{topology_key}, whenUnsatisfiable=#{when_unsatisfiable}, replicaSelector=#{selector}"
      filtered_nodes = nodes

      existing_pods = build_existing_pods(nodes)

      # Collect all domains
      all_domains = nodes.map { |n| node_topology_value(n, topology_key) }.uniq.compact

      # Count pods per domain, including zeros for empty domains
      pod_counts = Hash.new(0)
      existing_pods.each do |pod|
        next unless pod_matches_selector?(pod[:selector], selector)
        domain = node_topology_value(pod, topology_key)
        pod_counts[domain] += 1 if domain
      end
      all_domains.each { |d| pod_counts[d] ||= 0 }

      puts "[Scheduler] Initial pod counts per domain: #{pod_counts}"

      filtered_nodes = nodes.select do |entry|
        node = entry[:node]

        domain = node_topology_value(entry, topology_key)
        if domain.nil?
          #puts "[Scheduler] Skipping node #{node.node_id} missing topology key '#{topology_key}'"
          next false
        end

        count_in_domain = pod_counts[domain] || 0
        projected_count = count_in_domain + 1
        min_count = all_domains.map { |d| pod_counts[d] || 0 }.min
        skew = projected_count - min_count

        puts "[Scheduler] Node #{node.node_id} domain=#{domain} count=#{count_in_domain} projected=#{projected_count} skew=#{skew}"

        if skew > max_skew
          if when_unsatisfiable == "ScheduleAnyway"
            puts "[Scheduler] Skew #{skew} above maxSkew #{max_skew}, scheduling anyway"
            true
          else
            puts "[Scheduler] Skew #{skew} above maxSkew #{max_skew}, filtering out"
            false
          end
        else
          puts "[Scheduler] Skew #{skew} within maxSkew #{max_skew}, allowing"
          true
        end
      end

      puts "[Scheduler] PodTopologySpreadConstraint filtered nodes: #{filtered_nodes.map { |n| n[:node].node_id }}"
      filtered_nodes
    end

    private_class_method

    def self.build_existing_pods(nodes)
      existing_pods = []
      nodes.each do |entry|
        node = entry[:node]
        cluster = entry[:cluster]
        deployed_pods = entry[:deployed_pods] || []

        if deployed_pods && !deployed_pods.empty?
          puts "[Scheduler] Node #{node.node_id} in cluster #{cluster&.location_id || 'nil'} has deployed pods #{deployed_pods}"
        end

        deployed_pods.each do |pod_name|
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

    def self.count_matching_pods_per_domain(existing_pods, replica_selector, topology_key)
      counts = Hash.new(0)
      existing_pods.each do |pod|
        next unless pod_matches_selector?(pod[:selector], replica_selector)

        domain = node_topology_value(pod, topology_key)  # pass whole pod hash
        counts[domain] += 1 if domain
      end
      counts
    end

    def self.pod_matches_selector?(pod_selector, replica_selector)
      return false if pod_selector.nil? || replica_selector.nil?
      pod_selector.start_with?(replica_selector)
    end

    def self.node_topology_value(entry, topology_key)
      cluster = entry[:cluster]
      return nil unless cluster

      case topology_key
      when "location_id"
        cluster.location_id if cluster.respond_to?(:location_id)
      when "tier"
        cluster.tier if cluster.respond_to?(:tier)
      else
        nil
      end
    end

    #def self.compute_skew(domain_count, all_counts)
    #  return 0 if all_counts.empty?
    #  min_count = all_counts.min
    #  (domain_count - min_count).abs
    #end

  end
end
