#!/usr/bin/env sh

export_secrets_from_dir() {
  local secrets_dir=$1

  for filename in $secrets_dir/*; do
    local filename_without_path=${filename##*/}
    local filename_uppercased=$(echo $filename_without_path | tr 'a-z' 'A-Z');
    local filename_with_underscores=${filename_uppercased//-/_}

    local secret_name="SECRET_$filename_with_underscores";

    echo "Exporting secret $filename_without_path as $secret_name"

    local secret=$(<$filename);

    export "$secret_name=$secret"
  done
}

startup() {
  if [ -z ${FIAAS_ENVIRONMENT} ]; then
    echo "FIAAS_ENVIRONMENT is unset, not looking for secrets";
  else
    local secrets_dir="/var/run/secrets/fiaas"
    if [ ! -d "$secrets_dir" ]; then
      echo "Secrets directory '$secrets_dir' does not exist, not looking for secrets";
    else
      echo "FIAAS_ENVIRONMENT is set to '$FIAAS_ENVIRONMENT', looking for secrets in '$secrets_dir'";

      local secret_count=$(find $secrets_dir -type f | wc -l)

      if [ $secret_count -eq 0 ]; then
        echo "Found no secrets in '$secrets_dir'"
      else
        echo "Found $secret_count secret(s) in '$secrets_dir'"
        export_secrets_from_dir $secrets_dir
      fi
    fi
  fi

  node .
}

startup
