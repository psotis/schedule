#!/usr/bin/env bash
# Run on the VPS after uploading a release to /opt/rantevia/incoming/<release>.
set -euo pipefail
umask 077
component=${1:?backend or frontend required}
version=${2:?immutable release ID required}
[[ "$component" == backend || "$component" == frontend ]] || exit 2
[[ "$version" =~ ^[a-f0-9]{40}-[0-9]+-[0-9]+$ ]] || { echo 'Invalid release ID' >&2; exit 2; }
app_root=${RANTEVIA_ROOT:-/opt/rantevia}
app_dir="$app_root/schedule_srv"
stage="$app_root/incoming/$component-$version"
mkdir -p "$app_root/state"
# Shared by both repositories; never interrupt migrations with a newer release.
exec 9>"$app_root/state/deploy.lock"
flock -w 1800 9
[[ -f "$app_dir/.env.production" && -f "$stage/images.tar.gz" ]] || { echo 'Production configuration or release archive is missing' >&2; exit 1; }
cd "$app_dir"
export API_VERSION=local WEB_VERSION=local
if [[ -f "$app_root/state/backend-version" ]]; then API_VERSION=$(cat "$app_root/state/backend-version"); fi
if [[ -f "$app_root/state/frontend-version" ]]; then WEB_VERSION=$(cat "$app_root/state/frontend-version"); fi
for release in "$API_VERSION" "$WEB_VERSION"; do
  [[ "$release" == local || "$release" =~ ^[a-f0-9]{40}-[0-9]+-[0-9]+$ ]] || exit 2
done
compose_file="$app_dir/compose.production.yml"
if [[ "$component" == backend ]]; then
  compose_file="$stage/compose.production.yml"
  [[ -f "$compose_file" && -f "$stage/backup-postgres.sh" ]] || exit 1
  export API_VERSION="$version"
else
  [[ -f "$compose_file" && -f "$app_root/state/backend-version" ]] || { echo 'Deploy the backend before the frontend' >&2; exit 1; }
  export WEB_VERSION="$version"
fi
compose() {
  docker compose --project-directory "$app_dir" --env-file "$app_dir/.env.production" -f "$compose_file" --profile database "$@"
}
compose config --quiet
# No registry credentials are needed on the VPS. CI transfers built images over SSH.
docker load --input "$stage/images.tar.gz"
if [[ "$component" == backend ]]; then
  compose up -d --no-build --wait db
  # Also back up an empty first-install database. Never proceed if this fails.
  BACKUP_DIR="$app_root/backups" SERVICE_ENV_FILE="$app_dir/.env.production" COMPOSE_FILE_PATH="$compose_file" COMPOSE_PROJECT_DIRECTORY="$app_dir" bash "$stage/backup-postgres.sh"
  compose run --rm --no-deps migrate
  compose up -d --no-build --no-deps --wait api billing-worker
  install -m 644 "$stage/compose.production.yml" "$app_dir/compose.production.yml"
  mkdir -p "$app_dir/scripts"
  install -m 750 "$stage/backup-postgres.sh" "$app_dir/scripts/backup-postgres.sh"
  # Nginx resolves its API upstream on startup. Refresh it after replacing the API.
  if [[ "$WEB_VERSION" != local ]]; then compose up -d --no-build --no-deps --force-recreate --wait web; fi
else
  compose up -d --no-build --no-deps --wait web
fi
# Persist image selections for Docker Manager and direct Compose operations too.
python3 - "$app_dir/.env.production" <<'PYENV'
import os, re, sys, tempfile
from pathlib import Path
path = Path(sys.argv[1])
lines = [line for line in path.read_text().splitlines()
         if not re.match(r'^\s*(API_VERSION|WEB_VERSION)\s*=', line)]
lines += [f"API_VERSION={os.environ['API_VERSION']}", f"WEB_VERSION={os.environ['WEB_VERSION']}"]
fd, temporary = tempfile.mkstemp(prefix='.env.production.', dir=path.parent)
try:
    with os.fdopen(fd, 'w') as stream:
        stream.write('\n'.join(lines) + '\n')
    os.replace(temporary, path)
finally:
    if os.path.exists(temporary): os.unlink(temporary)
PYENV
# Persist versions only after health checks pass. Never undo database migrations.
printf '%s\n' "$version" > "$app_root/state/$component-version.next"
mv "$app_root/state/$component-version.next" "$app_root/state/$component-version"
printf 'Deployed %s release %s\n' "$component" "$version"
rm -f "$stage/images.tar.gz"
