#!/bin/bash

map_prefix() {
  case "$1" in
    fc)  echo "fog-cloud" ;;
    ec)  echo "edge-cloud" ;;
    efc) echo "edge-fog-cloud" ;;
    *)   echo "unknown" ;;
  esac
}

# Define testing variables here
FILES=("fc_cuttlefish_ramp_up_15min.conf" "fc_cuttlefish_random_bursts_15min.conf" "fc_cuttlefish_up_down_15min.conf"
       "ec_cuttlefish_ramp_up_15min.conf" "ec_cuttlefish_random_bursts_15min.conf" "ec_cuttlefish_up_down_15min.conf"
       "efc_cuttlefish_ramp_up_15min.conf" "efc_cuttlefish_random_bursts_15min.conf" "efc_cuttlefish_up_down_15min.conf"
       "fc_img_rec_ramp_up_15min.conf" "fc_img_rec_random_bursts_15min.conf" "fc_img_rec_up_down_15min.conf"
       "ec_img_rec_ramp_up_15min.conf" "ec_img_rec_random_bursts_15min.conf" "ec_img_rec_up_down_15min.conf"
       "efc_img_rec_ramp_up_15min.conf" "efc_img_rec_random_bursts_15min.conf" "efc_img_rec_up_down_15min.conf")

TEST_NAME="one"

for FILE in "${FILES[@]}"; do

  echo "Running experiments for config: $FILE"

  filename_without_ext="${FILE%.conf}"
  IFS='_' read -r PREFIX APP SCENARIO <<< "$filename_without_ext"

  PREFIX_DIR=$(map_prefix "$PREFIX")

  # Calculate base directory for results
  BASE_DIR="experiments/$TEST_NAME/$PREFIX_DIR/$APP/$SCENARIO"

  echo "PREFIX=$PREFIX_DIR"
  echo "APP=$APP"
  echo "SCENARIO=$SCENARIO"
  echo "BASE_DIR=$BASE_DIR"

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

  # Number of repetitions
  REPEAT=10

  for ((i=1; i<=REPEAT; i++)); do
      if [ ! -d "$BASE_DIR" ]; then
          echo "Creating base directory: $BASE_DIR"
          mkdir -p "$BASE_DIR"
      fi

      TEST_DIR="$BASE_DIR/run_$i"
      if [ ! -d "$TEST_DIR" ]; then
          echo "Creating test directory: $TEST_DIR"
          mkdir -p "$TEST_DIR"
      fi

      BENCH_DIR="$TEST_DIR/bench"
      if [ ! -d "$BENCH_DIR" ]; then
         echo "Creating bench directory: $BENCH_DIR"
         mkdir -p "$BENCH_DIR"
      fi

      export KUBETWIN_SEED=$RANDOM

      echo "-------------- Starting Run $i----------------------"
      echo "-------------- Using Seed $KUBETWIN_SEED ----------------------"
      for STRATEGY in "${STRATEGIES[@]}"; do
          STRATEGY_LOWER_CASE=$(echo "$STRATEGY" | tr '[:upper:]' '[:lower:]')

          # Update the strategy in the config file
          sed -i "s/^strategy .*/strategy :$STRATEGY/" examples/$FILE

          # Update the directories in the in the config file
          sed -i "s|^results_dir .*|results_csv_dir \"$BASE_DIR\"|" examples/$FILE
          sed -i "s|^bench_dir .*|bench_dir \"$BENCH_DIR\"|" examples/$FILE

          # Update the seed in the config file
          sed -i "s/seed 12345/seed $KUBETWIN_SEED/" examples/$FILE

          OUT_FILE="$TEST_DIR/$STRATEGY_LOWER_CASE.txt"
          # ensure file exists before redirect
          # touch "$OUT_FILE"

          echo "-------------- Running experiment with scheduling strategy: $STRATEGY ----------------------"
          bundle exec bin/kube_twin "examples/$FILE" > "$OUT_FILE"
      done
  done
done