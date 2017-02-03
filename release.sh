#!/usr/bin/env bash

set -e

if [[ -n $(git status -s) ]]
then
  echo git working directory is not clean
  exit 1
fi

versions=(${1//./ })

tag=finntech/node
onbuild_tag="$tag:onbuild"
test_tag="$tag:test"
test_onbuild_tag="$test_tag-onbuild"

major=${versions[0]}
minor=${versions[1]}

patch_and_revision=(${versions[2]//-/ })

patch=${patch_and_revision[0]}
revision=${patch_and_revision[1]}

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

if [[ -n "$revision" ]]
then
  tag_major="$tag_major-$revision"
  tag_minor="$tag_minor-$revision"
  tag_patch="$tag_patch-$revision"
  onbuild_tag_major="$onbuild_tag_major-$revision"
  onbuild_tag_minor="$onbuild_tag_minor-$revision"
  onbuild_tag_patch="$onbuild_tag_patch-$revision"
fi

echo This will create the following tags:
echo "$tag_major"
echo "$tag_minor"
echo "$tag_patch"
echo "$onbuild_tag_major"
echo "$onbuild_tag_minor"
echo "$onbuild_tag_patch"
echo "$test_tag_major"
echo "$test_tag_minor"
echo "$test_tag_patch"
echo "$test_onbuild_tag_major"
echo "$test_onbuild_tag_minor"
echo "$test_onbuild_tag_patch"

# http://stackoverflow.com/a/1885534/1850276
read -p "Do you want to continue? (yY)" -n 1 -r
echo # move to a new line

if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  exit 1
fi

echo Copying over base Dockerfiles

rm -rf build/

mkdir -p "build/$major/base/scripts"

cd "build/$major"

mkdir onbuild
mkdir test
mkdir test-onbuild

cp ../../Dockerfile.base base/Dockerfile
cp -r ../../scripts/ base/scripts/
cp ../../Dockerfile.onbuild onbuild/Dockerfile
cp ../../Dockerfile.test test/Dockerfile
cp ../../Dockerfile.test-onbuild test-onbuild/Dockerfile

echo Setting version in Dockerfiles to "$node_version"

# -i '' -e is necessary on OSX
# http://stackoverflow.com/a/19457213/1850276
find . -type f -exec sed -i '' -e  "s/0.0.0/$node_version/" {} \;

echo Building docker images

printf "\n\nBuilding base\n\n"

# Use subshells to print command being run
(
set -x

cd base/

docker build -t "$tag_major" -t "$tag_minor" -t "$tag_patch" .
)

printf "\n\nBuilding onbuild\n\n"

(
set -x

cd onbuild/

docker build -t "$onbuild_tag_major" -t "$onbuild_tag_minor" -t "$onbuild_tag_patch" .
)

printf "\n\nBuilding test\n\n"

(
set -x

cd test/

docker build -t "$test_tag_major" -t "$test_tag_minor" -t "$test_tag_patch" .
)

printf "\n\nBuilding test-onbuild\n\n"

(
set -x

cd test-onbuild/

docker build -t "$test_onbuild_tag_major" -t "$test_onbuild_tag_minor" -t "$test_onbuild_tag_patch" .
)

echo Pushing "$tag" to Docker Hub

docker push "$tag"

echo Tagging the commit, and pusing it to GitHub

git tag "$1" -m \""$1"\"

git push origin master --follow-tags
