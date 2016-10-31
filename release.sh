#!/usr/bin/env bash

if [[ -n $(git status -s) ]];
  then
    echo git working directory is not clean
    exit 1;
fi;

versions=(${1//./ })

tag=finntech/node
onbuild_tag=$tag:onbuild

major=${versions[0]}
minor=${versions[1]}

patch_and_revision=(${versions[2]//-/ })

patch=${patch_and_revision[0]}
revision=${patch_and_revision[1]}

tag_major=$tag:$major
tag_minor=$tag_major.$minor
tag_patch=$tag_minor.$patch
onbuild_tag_major=$onbuild_tag-$major
onbuild_tag_minor=$onbuild_tag_major.$minor
onbuild_tag_patch=$onbuild_tag_minor.$patch

if [[ -n $revision ]];
  then
    tag_major=$tag_major-$revision
    tag_minor=$tag_minor-$revision
    tag_patch=$tag_patch-$revision
    onbuild_tag_major=$onbuild_tag_major-$revision
    onbuild_tag_minor=$onbuild_tag_minor-$revision
    onbuild_tag_patch=$onbuild_tag_patch-$revision
fi;


docker build -t "$tag" -t "$tag_major" -t "$tag_minor" -t "$tag_patch" .

# Spawn a subshell to avoid `cd`ing back
(
cd onbuild/

docker build -t "$onbuild_tag" -t "$onbuild_tag_major" -t "$onbuild_tag_minor" -t "$onbuild_tag_patch" .
)

docker push $tag

git tag "$1" -m \""$1"\"

git push origin master --follow-tags
