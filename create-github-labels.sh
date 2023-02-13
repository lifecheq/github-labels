#!/usr/bin/env bash
##
# Populate GitHub project labels.
#
# @usage:
# Interactive prompt:
# ./create-github-labels
#
# Silent, if $GITHUB_TOKEN is set in environment and repository provided as an argument:
# ./create-github-labels myorg/myrepo
# gh repo list lifecheq --json "name"  | jq ".[].name"  | cut -f 2 -d\" | awk '{print "lifecheq/" $0}'
#
# shellcheck disable=SC2155

GITHUB_TOKEN="${GITHUB_TOKEN:-}"
REPO="${REPO:-$1}"
# Delete existing labels to mirror the list below.
DELETE_EXISTING_LABELS="${DELETE_EXISTING_LABELS:-1}"

# Array of labels to create. If DELETE_EXISTING_LABELS=1, the labels list will
# be exactly as below, otherwise labels below will be added to existing ones.
LABELS=(
  "Feature Flag? No" "B60205" "The change is not behind a feature flag, experiment, dark launch or similar"
  "Feature Flag? Yes" "0E8A16" "The change is behind a feature flag, experiment, dark launch or similar"
  "Risk: high" "E99695" "High Risk change"
  "Risk: low" "C2E0C6" "Low Risk change"
  "Risk: medium" "FEF2C0" "Medium Risk change"
)

## Labels that we will not delete
LABELS_TO_KEEP=(
  "adr" "FEE8DB" "To be able to exclude ADR PR from Github pullreminders"
)

main() {
  echo
  if [ "${DELETE_EXISTING_LABELS}" == "1" ]; then
    echo "This script will remove the default GitHub labels."
  else
    echo "This script will not remove the default GitHub labels."
  fi
  echo "This script will create new labels."
  echo "A personal access token is required to access private repositories."
  echo

  if [ "${REPO}" == "" ]; then
    echo ''
    echo -n 'GitHub Org/Repo (e.g. foo/bar): '
    read -r REPO
  else
    REPO="$1"
  fi

  if [ "${GITHUB_TOKEN}" == "" ]; then
    echo ''
    echo -n 'GitHub Personal Access Token: '
    read -r -s GITHUB_TOKEN
  fi

  REPO_USER=$(echo "$REPO" | cut -f1 -d /)
  REPO_NAME=$(echo "$REPO" | cut -f2 -d /)

  if ! user_has_access; then
    echo "User does not have access to specified repository. Please check your credentials" && exit 1
  fi

  echo
  echo "Starting label processing"
  echo

  timeout 3
  echo

  if [ "${DELETE_EXISTING_LABELS}" == "1" ]; then
    echo "Checking existing labels"
    existing_labels_strings="$(label_all)"
    # shellcheck disable=SC2207
    IFS=$'\n' existing_labels=($(xargs -n1 <<<"${existing_labels_strings}"))
    for existing_label_name in "${existing_labels[@]}"; do
      if ! is_provided_label "${existing_label_name}"; then
        echo "Removing label \"${existing_label_name}\" as it is not in thr provided list"
        if label_delete "${existing_label_name}"; then
          echo "  DELETED label \"${existing_label_name}\""
        else
          echo "  Unable to DELETE label \"${existing_label_name}\""
        fi
      fi
    done
  fi

  count=0
  for value in "${LABELS[@]}"; do
    if ((count % 3 == 0)); then
      name="${value}"
    elif ((count % 3 == 1)); then
      color="${value}"
    else
      description="${value}"

      echo "Processing label \"${name}\""
      if label_exists "${name}"; then
        if label_update "${name}" "${color}" "${description}"; then
          echo "  UPDATED label \"${name}\""
        else
          echo "  Unable to UPDATE label \"${name}\""
        fi
      else
        if label_create "${name}" "${color}" "${description}"; then
          echo "  CREATED label \"${name}\""
        else
          echo "  Unable to CREATE label \"${name}\""
        fi
      fi

    fi
    count=$((count + 1))
  done

  echo
  echo "Label processing complete"
  echo
}

is_provided_label() {
  label="${1}"

  count=0
  for value in "${LABELS[@]}"; do
    if ((count % 3 == 0)); then
      name="${value}"
      if [ "${label}" == "${name}" ]; then
        return 0
      fi
    fi
    count=$((count + 1))
  done

  count=0
  for value in "${LABELS_TO_KEEP[@]}"; do
    if ((count % 3 == 0)); then
      name="${value}"
      if [ "${label}" == "${name}" ]; then
        return 0
      fi
    fi
    count=$((count + 1))
  done

  return 1
}

user_has_access() {
  status=$(
    curl -s -I \
      -u "${GITHUB_TOKEN}":x-oauth-basic \
      --include -H "Accept: application/vnd.github.symmetra-preview+json" \
      -o /dev/null \
      -w "%{http_code}" \
      --request GET \
      "https://api.github.com/repos/${REPO_USER}/${REPO_NAME}/labels"
  )
  [ "${status}" == "200" ]
}

label_all() {
  response=$(
    curl -s \
      -u "${GITHUB_TOKEN}":x-oauth-basic \
      --include -H "Accept: application/vnd.github.symmetra-preview+json" \
      --request GET \
      "https://api.github.com/repos/${REPO_USER}/${REPO_NAME}/labels"
  )
  jsonval "${response}" "name"
}

label_exists() {
  local name="${1}"
  local name_encoded=$(uriencode "${name}")
  status=$(
    curl -s -I \
      -u "${GITHUB_TOKEN}":x-oauth-basic \
      --include -H "Accept: application/vnd.github.symmetra-preview+json" \
      -o /dev/null \
      -w "%{http_code}" \
      --request GET \
      "https://api.github.com/repos/${REPO_USER}/${REPO_NAME}/labels/${name_encoded}"
  )
  [ "${status}" == "200" ]
}

label_create() {
  local name="${1}"
  local color="${2}"
  local description="${3}"
  local status=$(
    curl -s \
      -u "${GITHUB_TOKEN}":x-oauth-basic \
      -H "Accept: application/vnd.github.symmetra-preview+json" \
      -o /dev/null \
      -w "%{http_code}" \
      --request POST \
      --data "{\"name\":\"${name}\",\"color\":\"${color}\", \"description\":\"${description}\"}" \
      "https://api.github.com/repos/${REPO_USER}/${REPO_NAME}/labels"
  )
  [ "${status}" == "201" ]
}

label_update() {
  local name="${1}"
  local color="${2}"
  local description="${3}"
  local name_encoded=$(uriencode "${name}")
  local status=$(
    curl -s \
      -u "${GITHUB_TOKEN}":x-oauth-basic \
      -H "Accept: application/vnd.github.symmetra-preview+json" \
      -o /dev/null \
      -w "%{http_code}" \
      --request PATCH \
      --data "{\"name\":\"${name}\",\"color\":\"${color}\", \"description\":\"${description}\"}" \
      "https://api.github.com/repos/${REPO_USER}/${REPO_NAME}/labels/${name_encoded}"
  )
  [ "${status}" == "200" ]
}

label_delete() {
  local name="${1}"
  local color="${2}"
  local description="${3}"
  local name_encoded=$(uriencode "${name}")
  local status=$(
    curl -s \
      -u "${GITHUB_TOKEN}":x-oauth-basic \
      -H "Accept: application/vnd.github.symmetra-preview+json" \
      -o /dev/null \
      -w "%{http_code}" \
      --request DELETE \
      "https://api.github.com/repos/${REPO_USER}/${REPO_NAME}/labels/${name_encoded}"
  )
  [ "${status}" == "204" ]
}

jsonval() {
  local json="${1}"
  local prop="${2}"

  temp=$(
    echo "${json}" |
      sed 's/\\\\\//\//g' |
      sed 's/[{}]//g' |
      awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' |
      sed 's/\"\:\"/\|/g' |
      sed 's/[\,]/ /g' |
      grep -w "${prop}" |
      cut -d":" -f2 |
      sed -e 's/^ *//g' -e 's/ *$//g'
  )
  temp="${temp//${prop}|/}"
  temp="$(echo "${temp}" | tr '\r\n' ' ')"

  echo "${temp}"
}

uriencode() {
  s="${1//'%'/%25}"
  s="${s//' '/%20}"
  s="${s//'"'/%22}"
  s="${s//'#'/%23}"
  s="${s//'$'/%24}"
  s="${s//'&'/%26}"
  s="${s//'+'/%2B}"
  s="${s//','/%2C}"
  s="${s//'/'/%2F}"
  s="${s//':'/%3A}"
  s="${s//';'/%3B}"
  s="${s//'='/%3D}"
  s="${s//'?'/%3F}"
  s="${s//'@'/%40}"
  s="${s//'['/%5B}"
  s="${s//']'/%5D}"
  printf %s "$s"
}

timeout() {
  local seconds=${1}
  while [ "${seconds}" -gt 0 ]; do
    echo -ne "Processing will start in $seconds seconds. Press Ctrl+C to abort\033[0K\r"
    sleep 1
    : $((seconds--))
  done
  echo
}

main "$@"

