#!/usr/bin/env bash
set -euo pipefail

export HTTPS_PROXY="$OC_PROXY"

# Script to print logs of a GitLab job by providing MR ID and job name

# Check if required arguments are provided
if [ $# -lt 2 ]; then
  echo "Usage: $0 <merge_request_id> <job_name>"
  echo "Options:"
  echo "  --stream: Keep watching the job logs while the job is running"
  exit 1
fi

curl_gitlab_api=(curl -k -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN")

# Helper function for keyset pagination to retrieve all pages from GitLab API
# Arguments:
#   $1: API endpoint (full URL path after base API URL)
#   $2: Resource name for logging (e.g., "jobs", "projects")
#   $3: (Optional) Additional query parameters as a string (e.g., "&scope=all")
function get_all_pages_keyset() {
  local endpoint="$1"
  local resource_name="$2"
  local extra_params="${3:-}"

  echo >&2 "Fetching all $resource_name using keyset pagination..."

  local url="$GITLAB_API/$endpoint?pagination=keyset&per_page=100&order_by=id&sort=asc$extra_params"
  local all_results="[]"
  local page_count=0

  while true; do
    page_count=$((page_count + 1))
    echo >&2 "Retrieving page $page_count of $resource_name..."

    # Make the API request and capture both headers and body
    local response
    local headers
    local body

    # Use temporary files to store headers and body
    local header_file=$(mktemp)
    local body_file=$(mktemp)

    # Make API call with curl, saving headers and body separately
    response=$("${curl_gitlab_api[@]}" -D "$header_file" "$url" >"$body_file")

    # Read headers and body from files
    headers=$(cat "$header_file")
    body=$(cat "$body_file")

    # Clean up temp files
    rm -f "$header_file" "$body_file"

    # Parse the response body as JSON
    if ! echo "$body" | jq empty >/dev/null 2>&1; then
      echo "Error: Failed to parse response as JSON"
      echo "Response: $body"
      return 1
    fi

    # Merge with existing results
    all_results=$(echo "$all_results" | jq --argjson new_items "$body" '. + $new_items')

    # Extract the Link header to find the next page URL
    local next_link=$(echo "$headers" | grep -i "Link:" | grep -o '<[^>]*>; rel="next"' | sed 's/<\([^>]*\)>; rel="next"/\1/')

    # If there's no next link, we've reached the last page
    if [ -z "$next_link" ]; then
      break
    fi

    # Update URL for the next page
    url="$next_link"
  done

  echo >&2 "Completed retrieval of $resource_name: $(echo "$all_results" | jq length) total items across $page_count pages"
  echo "$all_results"
}

# Assign arguments to variables
MR_ID="$1"
JOB_NAME="$2"
STREAM_OPTION="${3:-""}"

# Get the pipeline ID associated with the merge request
echo "Fetching pipeline ID for MR $MR_ID..."
PIPELINE_ID=$("${curl_gitlab_api[@]}" \
  "$GITLAB_API/projects/$GITLAB_PROJECT_ID/merge_requests/$MR_ID/pipelines?per_page=1" |
  jq -r '.[0].id')

if [ -z "$PIPELINE_ID" ] || [ "$PIPELINE_ID" == "null" ]; then
  echo "Error: Could not find pipeline for MR $MR_ID"
  exit 1
fi

echo "Found pipeline ID: $PIPELINE_ID"

# Get list of jobs for the pipeline
echo "Fetching jobs for pipeline $PIPELINE_ID..."
JOBS=$(get_all_pages_keyset "projects/$GITLAB_PROJECT_ID/pipelines/$PIPELINE_ID/jobs" "jobs")

# Find the job ID for the specified job name
JOB_ID=$(echo $JOBS | jq -r ".[] | select(.name == \"$JOB_NAME\") | .id")
JOB_STATUS=$(echo $JOBS | jq -r ".[] | select(.name == \"$JOB_NAME\") | .status")

if [ -z "$JOB_ID" ] || [ "$JOB_ID" == "" ]; then
  echo "Error: Could not find job with name '$JOB_NAME' in pipeline $PIPELINE_ID"
  exit 1
fi

echo "Found job ID: $JOB_ID for job name: $JOB_NAME (Status: $JOB_STATUS)"

# Fetch and print the job log
if [ "$STREAM_OPTION" == "--stream" ] && [ "$JOB_STATUS" == "running" ]; then
  echo >&2 "Seems not supported"
  #echo "Streaming logs for job $JOB_ID..."
  #
  ## Initial log position
  #LAST_SIZE=0
  #
  ## Continue streaming logs until job is finished
  #while true; do
  #    # Get current job status
  #    CURRENT_STATUS=$("${curl_gitlab_api[@]}" \
  #        "$GITLAB_API/projects/$GITLAB_PROJECT_ID/jobs/$JOB_ID" | jq -r '.status')
  #
  #    # Get log with range header to fetch only new content
  #    RESPONSE=$("${curl_gitlab_api[@]}" \
  #        --header "Range: bytes=$LAST_SIZE-" \
  #        "$GITLAB_API/projects/$GITLAB_PROJECT_ID/jobs/$JOB_ID/trace")
  #
  #    # Update the last size
  #    CURRENT_SIZE=$("${curl_gitlab_api[@]}" -I \
  #        "$GITLAB_API/projects/$GITLAB_PROJECT_ID/jobs/$JOB_ID/trace" | \
  #        grep -i content-length | awk '{print $2}' | tr -d '\r')
  #
  #    # If we got a valid size, update it
  #    if [[ -n "$CURRENT_SIZE" && "$CURRENT_SIZE" != "0" ]]; then
  #        LAST_SIZE=$CURRENT_SIZE
  #    fi
  #
  #    # Print the new content if any
  #    if [[ -n "$RESPONSE" ]]; then
  #        echo -n "$RESPONSE"
  #    fi
  #
  #    # Exit if job is complete
  #    if [[ "$CURRENT_STATUS" != "running" && "$CURRENT_STATUS" != "pending" ]]; then
  #        echo -e "\nJob finished with status: $CURRENT_STATUS"
  #        break
  #    fi
  #
  #    # Sleep to avoid too frequent requests
  #    sleep 3
  #done
else
  echo "Fetching logs for job $JOB_ID..."
  "${curl_gitlab_api[@]}" \
    "$GITLAB_API/projects/$GITLAB_PROJECT_ID/jobs/$JOB_ID/trace"
fi
