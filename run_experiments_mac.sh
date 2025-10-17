#!/bin/bash

TEST="cuttlefish_ramp_up_15min.conf"
BASE_DIR="experiments/cuttlefish/ramp_up_15min_v2"

STRATEGIES=(
  "BALANCED_WITH_TOPOLOGY"
  "BALANCED"
  "DIKTYO"
  "NODE_AFFINITY"
  "TRIMARAN_LOW_RISK"
  "TOPOLOGY_AWARE"
  "LEAST_ALLOCATABLE"
  "MOST_ALLOCATABLE"
  "RESOURCE_AVAILABILITY"
  "COST_AWARE"
  "DIKTYO_COST"
  "DIKTYO_RISK"
  "DIKTYO_TOPOLOGY"
)

REPEAT=5
TEMPLATE="examples/$TEST" # keep the original pristine

for ((i = 1; i <= REPEAT; i++)); do
  TEST_DIR="$BASE_DIR/run_$i"
  mkdir -p "$TEST_DIR"
  echo "-------------- Starting Run $i ----------------------"

  for STRATEGY in "${STRATEGIES[@]}"; do
    # Work on a per-strategy copy to avoid permanently mutating the template
    WORKFILE="$(mktemp)"
    cp "$TEMPLATE" "$WORKFILE"

    # BSD sed in-place: note the '' after -i (no backup file created)
    sed -i '' "s/^strategy .*/strategy :$STRATEGY/" "$WORKFILE"

    # Lowercase file name in a portable way
    out_name="$(printf '%s' "$STRATEGY" | tr '[:upper:]' '[:lower:]')"

    echo "-------------- Running experiment with scheduling strategy: $STRATEGY ----------------------"
    bundle exec bin/kube_twin "$WORKFILE" >"$TEST_DIR/${out_name}.txt"

    rm -f "$WORKFILE"
  done
done
