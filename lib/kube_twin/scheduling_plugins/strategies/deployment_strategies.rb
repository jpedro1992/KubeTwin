require_relative './../filter/cpu_resources'
require_relative './../filter/mem_resources'
require_relative './../score/node_affinity'
require_relative './../score/resource_availability'
require_relative './../score/node_resources_least_allocatable'
require_relative './../score/node_resources_most_allocatable'
require_relative './../score/trimaran_low_risk_over_commitment'
require_relative './../score/topology_cluster'
require_relative './../score/cost_aware'
require_relative './../score/diktyo'
require_relative './../filter/pod_topology_constraint'

module KUBETWIN

KUBE_SCHEDULER_STRATEGIES = {
  COST_AWARE: {
    filters: [
      KUBETWIN::CPUFilter.method(:run),
      KUBETWIN::MEMFilter.method(:run),
    ],
    scores: [
      KUBETWIN::CostAware.method(:run),
    ]
  },
  DIKTYO: {
    filters: [
      KUBETWIN::CPUFilter.method(:run),
      KUBETWIN::MEMFilter.method(:run),
    ],
    scores: [
      KUBETWIN::DiktyoScoring.method(:run),
    ]
  },
  DIKTYO_COST: {
    filters: [
      KUBETWIN::CPUFilter.method(:run),
      KUBETWIN::MEMFilter.method(:run),
    ],
    scores: [
      KUBETWIN::DiktyoScoring.method(:run),
      KUBETWIN::CostAware.method(:run),
    ]
  },
  DIKTYO_TOPOLOGY: {
    filters: [
      KUBETWIN::CPUFilter.method(:run),
      KUBETWIN::MEMFilter.method(:run),
      KUBETWIN::PodTopologySpreadConstraint.method(:run)
    ],
    scores: [
      KUBETWIN::DiktyoScoring.method(:run),
      KUBETWIN::TopologyClusterAggregate.method(:run),
    ]
  },
  DIKTYO_RISK: {
    filters: [
      KUBETWIN::CPUFilter.method(:run),
      KUBETWIN::MEMFilter.method(:run),
    ],
    scores: [
      KUBETWIN::DiktyoScoring.method(:run),
      KUBETWIN::LowRiskOverCommitment.method(:run),
    ]
  },
  RESOURCE_AVAILABILITY: {
    filters: [
      KUBETWIN::CPUFilter.method(:run),
      KUBETWIN::MEMFilter.method(:run),
    ],
    scores: [
      KUBETWIN::ResourceAvailabilityScore.method(:run),
    ]
  },
  MOST_ALLOCATABLE: {
    filters: [
      KUBETWIN::CPUFilter.method(:run),
      KUBETWIN::MEMFilter.method(:run),
    ],
    scores: [
      KUBETWIN::NodeResourcesMostAllocatable.method(:run),
    ]
  },
  LEAST_ALLOCATABLE: {
    filters: [
      KUBETWIN::CPUFilter.method(:run),
      KUBETWIN::MEMFilter.method(:run),
    ],
    scores: [
      KUBETWIN::NodeResourcesLeastAllocatable.method(:run),
    ]
  },
  TOPOLOGY_AWARE: {
    filters: [
      KUBETWIN::CPUFilter.method(:run),
      KUBETWIN::MEMFilter.method(:run),
      KUBETWIN::PodTopologySpreadConstraint.method(:run)
    ],
    scores: [
      KUBETWIN::TopologyClusterAggregate.method(:run),
    ]
  },
  TRIMARAN_LOW_RISK: {
    filters: [
      KUBETWIN::CPUFilter.method(:run),
      KUBETWIN::MEMFilter.method(:run),
    ],
    scores: [
      KUBETWIN::LowRiskOverCommitment.method(:run),
    ]
  },
  NODE_AFFINITY: {
    filters: [
      KUBETWIN::CPUFilter.method(:run),
      KUBETWIN::MEMFilter.method(:run),
    ],
    scores: [
      KUBETWIN::NodeAffinityScore.method(:run),
    ]
  },
  BALANCED: {
    filters: [
      KUBETWIN::CPUFilter.method(:run),
      KUBETWIN::MEMFilter.method(:run),
    ],
    scores: [
      KUBETWIN::LowRiskOverCommitment.method(:run),
      KUBETWIN::TopologyClusterAggregate.method(:run),
      KUBETWIN::ResourceAvailabilityScore.method(:run),
      KUBETWIN::NodeResourcesLeastAllocatable.method(:run),
      KUBETWIN::NodeResourcesMostAllocatable.method(:run),
      KUBETWIN::CostAware.method(:run),
      KUBETWIN::DiktyoScoring.method(:run),
    ]
  },
  BALANCED_WITH_TOPOLOGY: {
    filters: [
      KUBETWIN::CPUFilter.method(:run),
      KUBETWIN::MEMFilter.method(:run),
      KUBETWIN::PodTopologySpreadConstraint.method(:run)
    ],
    scores: [
      KUBETWIN::LowRiskOverCommitment.method(:run),
      KUBETWIN::TopologyClusterAggregate.method(:run),
      KUBETWIN::ResourceAvailabilityScore.method(:run),
      KUBETWIN::NodeResourcesLeastAllocatable.method(:run),
      KUBETWIN::NodeResourcesMostAllocatable.method(:run),
      KUBETWIN::CostAware.method(:run),
      KUBETWIN::DiktyoScoring.method(:run),
    ]
  },
}
end