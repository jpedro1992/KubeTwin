#!/env/bin/bash

TEST=("cuttlefish_ramp_up_15min.conf" "cuttlefish_random_bursts_15min.conf" "cuttlefish_up_down_15min.conf")

for test_case in "${TEST[@]}"; do

  echo "Running experiments for test case: $test_case"
  EXP_NAME=$(echo $test_case | cut -d'.' -f1)

  BASE_DIR="experiments/cuttlefish/$EXP_NAME"

  #echo "Base directory for results: $BASE_DIR"

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

    export KUBETWIN_SEED=$RANDOM
    TEST_DIR="$BASE_DIR/run_$i"
    mkdir -p "$TEST_DIR"
    echo "-------------- Starting Run $i ----------------------"
    echo "-------------- Using Seed $KUBETWIN_SEED ----------------------"

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
done
