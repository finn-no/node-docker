#!/usr/bin/env sh

log() {
  message="$1"
  message_with_escaped_quotes="$(echo "$message" | sed 's/"/\\"/g')"
  echo "message" $message
  echo "message_with…" $message_with_escaped_quotes

  iso_8601_timestamp="$(date +%Y-%m-%dT%H:%M:%S%z)"
  printf '{"@version": 1, "@timestamp": "%s", "level": "INFO", "message": "%s"}\n' "$iso_8601_timestamp" "$message_with_escaped_quotes"
}

export_secrets_from_dir() {
  for filename in "$SECRETS_DIR"/*; do
    filename_without_path="${filename##*/}"
    filename_uppercased="$(echo "$filename_without_path" | tr '[:lower:]' '[:upper:]')"
    filename_with_underscores="$(echo "$filename_uppercased" | tr '-' '_')"

    secret_name="SECRET_$filename_with_underscores";

    log "Exporting secret '$filename_without_path' as '$secret_name'"

    secret="$(cat "$filename")"

    export "$secret_name=$secret"
  done
}

start_app() {
  # npm provides binaries on PATH in scripts, so we have to do the same
  path_with_node_modules_binaries="$PATH:$(pwd)/node_modules/.bin"

  # Fetch 'start' script from package.json
  start_script="PATH=$path_with_node_modules_binaries $(node -p "require('./package.json').scripts.start")"

  # Execute the script
  eval "$start_script"
}

startup() {
  if [ -z "$FIAAS_ENVIRONMENT" ]; then
    log "FIAAS_ENVIRONMENT is unset; not looking for secrets";
  else
    if [ ! -d "$SECRETS_DIR" ]; then
      log "Secrets directory '$SECRETS_DIR' does not exist; not looking for secrets";
    else
      log "FIAAS_ENVIRONMENT is set to '$FIAAS_ENVIRONMENT'; looking for secrets in '$SECRETS_DIR'";

      # Count number of files, then trim leading whitespace
      secret_count="$(find "$SECRETS_DIR" -type f | wc -l | tr -d ' ')"

      if [ "$secret_count" -eq 0 ]; then
        log "Found no secrets in '$SECRETS_DIR'"
      else
        log "Found $secret_count secret(s) in '$SECRETS_DIR'"
        export_secrets_from_dir
      fi
    fi
  fi

  start_app
}

startup
