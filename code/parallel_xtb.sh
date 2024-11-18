#!/bin/bash

#SBATCH --job-name=xtb_parallel
#SBATCH --cpus-per-task=1
#SBATCH --ntasks=10  # Set to the number of cores you'd like to use
#SBATCH --mem=1GB # Total memory for the job
#SBATCH --time=00:05:00 # Time limit
#SBATCH --output=xtb_parallel.out # Output file
#SBATCH --error=xtb_parallel.err # Error file
#SBATCH --partition=veryshort
#SBATCH --account=CHEM014742
# Load the xtb conda environment
source activate base
conda activate xtb_env

# Set the maximum number of parallel jobs to the number of available cores
MAX_JOBS=$SLURM_NTASKS

# Set the input directory and output directory

cd ../data/output_files

FILE_LIST=(../input_files/*.xyz)

echo "Maximum number of parallel jobs: $MAX_JOBS"

# Print all files in FILE_LIST
echo "Printing all files in FILE_LIST:"
for file in "${FILE_LIST[@]}"; 
    do echo "$file"
done

# Function to run xtb for each file
for INPUT_FILE in "${FILE_LIST[@]}"; do
    BASE_NAME=$(basename "$INPUT_FILE" .xyz)
    
    # Create an output directory for the current xtb file
    mkdir -p "$BASE_NAME"
    # Move into the directory and run xtb

    # Run `xtb` in parallel using `srun`
    srun --exclusive -N1 -n1 bash -c "
	cd '$BASE_NAME' || exit
	echo 'Starting xtb on $INPUT_FILE at $(date)' # Start time
	xtb coord '../$INPUT_FILE' --opt > /dev/null 2>&1
	echo 'Finished xtb on $INPUT_FILE at $(date)' # End time
    " &

    # Wait if the number of background jobs reaches the maximum
    if [[ $(jobs -r -p | wc -l) -ge $MAX_JOBS ]]; then
	 wait -n # Wait for any job to finish before continuing
    fi
done
# Wait for all background jobs to finish
wait
echo "All jobs completed."
