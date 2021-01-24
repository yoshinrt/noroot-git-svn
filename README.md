# noroot-git-svn

This is a Makefile that installs git-svn locally if you want to use git-svn but don't have root privileges.
git, svn and perl will be installed locally.

git-svn を使いたいがroot権限がない場合に，ローカルにgit-svnをインストールするMakefileです．
perl, svn, git をローカルにインストールする力技で解決します．

## usage

make SRC_DIR=<tarball_download_dir> DST_DIR=<install_dir> download all
