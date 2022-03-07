#!/usr/bin/env bash

set -o errexit -o pipefail -o nounset -o errtrace
err_report() {
  echo "ERROR on line $(caller)" >&2
}
trap 'err_report' ERR

if [[ ${1:-} != "build" && ${1:-} != "push" && ${1:-} != "buildlocal" || $# -ne 2 ]]; then
  echo "Usage: $0 [build|buildlocal|push] nodeVersion"
  echo "  e.g. $0 push 12.12.0       # build and push image to docker repository, and push tags to git"
  echo "       $0 build 12.12.0-6    # 6th iteration of the node 12.12.0 image"
  echo "       $0 buildlocal 12.12.0 # build image for local arch and store in local docker cache"
  exit 1
fi

COMMAND=$1
VERSION=$2

# xargs on mac throws on unknown flags, but the behavior is the default. So try
# to run it, and if it fails, use plain `xargs`
xargs_command="xargs --no-run-if-empty"

if ! echo "" | ${xargs_command} >/dev/null 2>&1; then
  xargs_command="xargs"
fi

if [[ $COMMAND == "push" && -n $(git status -s) ]]; then
  echo git working directory is not clean
  exit 1
fi

versions=(${VERSION//./ })

tag=containers.schibsted.io/finntech/nodejs
onbuild_tag="$tag:onbuild"
test_tag="$tag:test"
test_onbuild_tag="$test_tag-onbuild"

major=${versions[0]}
minor=${versions[1]}

patch_and_revision=(${versions[2]//-/ })

patch=${patch_and_revision[0]}
revision=${patch_and_revision[1]:-}

node_version="$major.$minor.$patch"

tag_major="$tag:$major"
tag_minor="$tag_major.$minor"
tag_patch="$tag_minor.$patch"
onbuild_tag_major="$onbuild_tag-$major"
onbuild_tag_minor="$onbuild_tag_major.$minor"
onbuild_tag_patch="$onbuild_tag_minor.$patch"
test_tag_major="$test_tag-$major"
test_tag_minor="$test_tag_major.$minor"
test_tag_patch="$test_tag_minor.$patch"
test_onbuild_tag_major="$test_onbuild_tag-$major"
test_onbuild_tag_minor="$test_onbuild_tag_major.$minor"
test_onbuild_tag_patch="$test_onbuild_tag_minor.$patch"

if [[ $COMMAND == "push" ]]; then
  echo "You are pushing, so this will create the following tags:\n\n"
else
  echo "You are just building, but a push would have created the following tags:"
fi
echo "
$tag_major
$tag_minor
$tag_patch
$onbuild_tag_major
$onbuild_tag_minor
$onbuild_tag_patch
$test_tag_major
$test_tag_minor
$test_tag_patch
$test_onbuild_tag_major
$test_onbuild_tag_minor
$test_onbuild_tag_patch
"

# http://stackoverflow.com/a/1885534/1850276
read -p "Do you want to continue? (yN)" -n 1 -r
echo # move to a new line

if [[ $REPLY != "y" ]]; then
  exit 1
fi

printf "\n\nDeleting old container images\n\n"

# Because we might get
# "Error response from daemon: conflict: unable to delete 053f4edd648c (cannot be forced) - image has dependent child images"
# we need to run in a loop to do multiple runs

images_for_deletion() {
  local deleteimages=""
  local nodeimages=$(docker images | awk -v tag="$tag" '$0 ~ tag { print $3 }')
  local allimages=$(docker images -q)
  for image in $allimages; do
    printf . >&2
    local imagehistory=$(docker history -q $image)
    for nodeimage in $nodeimages; do
      for history in $imagehistory; do
        if [[ $history == $nodeimage && $deleteimages != *"$image"* ]]; then
          deleteimages+=" $image"
        fi
      done
    done
  done
  echo $deleteimages
}
while true; do
  printf · >&2
  deleteimages=$(images_for_deletion)
  if [[ $deleteimages == "" ]]; then
    break
  fi
  for del in $deleteimages; do
    printf "\nDeleting image $del"
    docker image rm -f $del || true
  done
done

printf "\n\nCopying over base Dockerfiles\n\n"

rm -rf build/
mkdir -p "build/$major"
cd "build/$major"

for image in base onbuild test test-onbuild; do
  mkdir $image
  cp ../../Dockerfile.base $image/Dockerfile
  cp -r ../../scripts $image/
done
cat ../../Dockerfile.onbuild >> onbuild/Dockerfile
cat ../../Dockerfile.test >> test/Dockerfile
cat ../../Dockerfile.test >> test-onbuild/Dockerfile
cat ../../Dockerfile.test-onbuild >> test-onbuild/Dockerfile

echo Setting version in Dockerfiles to "$node_version"

# -i "" -e is necessary on OSX
# http://stackoverflow.com/a/19457213/1850276
find . -type f -exec sed -i "" -e "s/NODE_VERSION_TEMPLATE/$node_version/" {} \;

echo Building docker images

# Use subshells to print command being run

BUILD_ARGS="buildx build"
if [[ $COMMAND == "buildlocal" ]]; then
  if [[ $(uname -m) == "arm64" ]]; then
    BUILD_ARGS+=" --load --platform linux/arm64"
  else
    BUILD_ARGS+=" --load --platform linux/amd64"
  fi
else
  BUILD_ARGS+=" --platform linux/arm64,linux/amd64"
fi

if [[ $COMMAND == "push" ]]; then
  BUILD_ARGS+=" --push"
fi

BUILDX_NODE="$(docker buildx create --use)"

printf "\n\nBuilding base\n\n"
(
  set -x
  cd base/
  # This one does `pull` to ensure we've got the latest upstream image
  docker $BUILD_ARGS --pull --squash -t "$tag_major" -t "$tag_minor" -t "$tag_patch" .
)

printf "\n\nBuilding onbuild\n\n"
(
  set -x
  cd onbuild/
  docker $BUILD_ARGS -t "$onbuild_tag_major" -t "$onbuild_tag_minor" -t "$onbuild_tag_patch" .
)

printf "\n\nBuilding test\n\n"
(
  set -x
  cd test/
  docker $BUILD_ARGS --squash -t "$test_tag_major" -t "$test_tag_minor" -t "$test_tag_patch" .
)

printf "\n\nBuilding test-onbuild\n\n"
(
  set -x
  cd test-onbuild/
  docker $BUILD_ARGS -t "$test_onbuild_tag_major" -t "$test_onbuild_tag_minor" -t "$test_onbuild_tag_patch" .
)

if [[ $COMMAND == "push" ]]; then
  echo Tagging the commit, and pushing it to GitHub
  git tag "$VERSION" -m \""$VERSION"\"
  git push origin master --follow-tags
else
  printf "\nThis is just a build, so new images are NOT pushed and tagged\n\n"
fi

docker buildx rm "$BUILDX_NODE"
