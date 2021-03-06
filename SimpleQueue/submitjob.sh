#!/bin/bash

module load Tools/SimpleQueue
job=1

# Loop over the command line arguments
for FILE in "$@"; do
  # Create the tasklist file needed by SimpleQueue
  cat "$FILE" | head -200 |
      xargs -n 3 echo "cd $(pwd); ./task.sh" > TaskList.$job

  # Create the job script
  sqCreateScript -q fas_devel -m 8 -w 1:00:00 -n 1 TaskList.$job > Job-$job.sh

  # Submit the generated script
  # XXX fake it for now
  echo qsub -m abe Job-$job.sh

  # Wait for job to finish running: there isn't an easy way to do this
  # XXX fake it for now
  echo sleep 3600

  # Increment the job count
  job=$(($job + 1))
done
