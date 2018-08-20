#!/usr/bin/env sh

log() {
  local message=$1
  local iso_8601_timestamp=$(date +%Y-%m-%dT%H:%M:%S%z)
  echo '{"@version": 1, "@timestamp": "'"$iso_8601_timestamp"'", "level": "INFO", "message": "'"$1"'"}'
}

export_secrets_from_dir() {
  local secrets_dir=$1

  for filename in $secrets_dir/*; do
    local filename_without_path=${filename##*/}
    local filename_uppercased=$(echo $filename_without_path | tr 'a-z' 'A-Z');
    local filename_with_underscores=${filename_uppercased//-/_}

    local secret_name="SECRET_$filename_with_underscores";

    log "Exporting secret '$filename_without_path' as '$secret_name'"

    local secret=$(<$filename);

    export "$secret_name=$secret"
  done
}

start_app() {
  # npm provides binaries on PATH in scripts, so we have to do the same
  export PATH=$PATH:$(pwd)/node_modules/.bin

  local start_script=$(node -p "require('./package.json').scripts.start")

  $start_script
}

startup() {
  if [ -z ${FIAAS_ENVIRONMENT} ]; then
    log "FIAAS_ENVIRONMENT is unset, not looking for secrets";
  else
    local secrets_dir="/var/run/secrets/fiaas"
    if [ ! -d "$secrets_dir" ]; then
      log "Secrets directory '$secrets_dir' does not exist, not looking for secrets";
    else
      log "FIAAS_ENVIRONMENT is set to '$FIAAS_ENVIRONMENT', looking for secrets in '$secrets_dir'";

      # Count number of files, then trim leading whitespace
      local secret_count=$(find $secrets_dir -type f | wc -l | tr -d ' ')

      if [ $secret_count -eq 0 ]; then
        log "Found no secrets in '$secrets_dir'"
      else
        log "Found '$secret_count' secret(s) in '$secrets_dir'"
        export_secrets_from_dir $secrets_dir
      fi
    fi
  fi

  start_app
}

startup
