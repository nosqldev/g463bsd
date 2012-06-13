#!/bin/sh

KERNCONF='DOG'

# {{{ Basic Functions

gputs()
{
    printf "\033[01;32m$1\033[00m\n"
}

cputs()
{
    printf "\033[01;36;40m$1\033[00m\n"
}

warn_puts()
{
    printf "\033[01;33;41m$1\033[00m\n"
}

md5_check()
{
    MD5SUM=`md5 -q $1`
    if [ "$MD5SUM" != "$2" ]
    then
        warn_puts "$1 md5 checksum is incorrect"
        exit 1
    fi
}

print_help()
{
    echo "Usage:"
    echo "	-c		Clean environment including datanode.log, data/ and generated reports"
    echo "	--rebuild	Clean environment and make"
    echo "	--cleanall	Delete all unused files and directories including tmp/ and utils/"
    echo "	-d		Display necessary env"
    echo "	--install	Download and install third-party softwares"
    echo "	-i		Print machine hard info"
}

run_cmd()
{
    printf "\033[01;32m$1\033[00m\n"
    printf "\033[01;30;40m"
    $1
    if [ $? != 0 ]
    then
        printf "\033[01;33;41mFailed: $1\033[00m\n"
        exit 1
    fi
    printf "\033[00m"
}

assert_cmd()
{
    if [ $? != 0 ]
    then
        printf "\033[01;33;41mFailed: $1\033[00m\n"
        exit 1
    fi
    printf "\033[01;32m[assert] $1\033[00m\n"
}

# }}}
# {{{ Install Packages

RUN_DIR=`pwd`
export LANG="C"

run_cmd "pkg_add -r git"
run_cmd "pkg_add -r screen"
cd /usr/ports/editors/vim
gputs "cd /usr/ports/editors/vim"
run_cmd "make NO_GUI=yes WITH_CSCOPE=yes install clean"
run_cmd "pkg_add -r cvsup-without-gui"
run_cmd "pkg_add -r wget"
run_cmd "pkg_add -r lftp"
run_cmd "pkg_add -r pciutils"
run_cmd "pkg_add -r gmake"
run_cmd "pkg_add -r mercurial"
run_cmd "pkg_add -r gmp"
run_cmd "pkg_add -r zip"
run_cmd "pkg_add -r binutils"
run_cmd "pkg_add -r math_mpc"

# }}}
# {{{ Download & Install GCC 4.6.3

cd
run_cmd "mkdir gcc"
cd gcc
run_cmd "wget ftp://ftp.dti.ad.jp/pub/lang/gcc/releases/gcc-4.6.3/gcc-4.6.3.tar.bz2"
run_cmd "tar xfvj gcc-4.6.3.tar.bz2"

cd
cd gcc/gcc-4.6.3
run_cmd "mkdir -p objdir"
cd objdir
run_cmd "../configure --prefix=/lib/gcc46"
run_cmd "gmake -j4"
run_cmd "gmake install"

# }}}
# {{{ Update Source Tree

cd $RUN_DIR
run_cmd "cp /usr/share/examples/cvsup/ports-supfile ."
run_cmd "cp /usr/share/examples/cvsup/stable-supfile ."
sed -i.bak 's/CHANGE_THIS/cvsup3/' ports-supfile
sed -i.bak 's/RELENG_9/RELENG_9_0/' stable-supfile
sed -i.bak 's/CHANGE_THIS/cvsup/' stable-supfile
run_cmd "cvsup -g -L 2 stable-supfile"
run_cmd "cvsup -g -L 2 ports-supfile"

# }}}
# {{{ Update Configurations: /etc
# {{{ libmap.conf

cd $RUN_DIR
touch /etc/libmap.conf
sed -i.bak '/APPEND BY buildenv.sh/,/EOL [buildenv.sh]/d' /etc/libmap.conf
cputs "sed -i.bak '/APPEND BY buildenv.sh/,/EOL [buildenv.sh]/d' /etc/libmap.conf"
cat append_libmap.txt >> /etc/libmap.conf
cputs "cat append_libmap.txt >> /etc/libmap.conf"

# }}}
# {{{ make.conf

touch /etc/make.conf
sed -i.bak '/APPEND BY buildenv.sh/,/EOL [buildenv.sh]/d' /etc/make.conf
cputs "sed -i.bak '/APPEND BY buildenv.sh/,/EOL [buildenv.sh]/d' /etc/make.conf"
cat append_make.txt >> /etc/make.conf
cputs "cat append_make.txt >> /etc/make.conf"

# }}}
# {{{ src.conf

touch /etc/src.conf
sed -i.bak '/APPEND BY buildenv.sh/,/EOL [buildenv.sh]/d' /etc/src.conf
cputs "sed -i.bak '/APPEND BY buildenv.sh/,/EOL [buildenv.sh]/d' /etc/src.conf"
cat append_src.txt >> /etc/src.conf
cputs "cat append_src.txt >> /etc/src.conf"

# }}}
# }}}

# {{{ md5 check
md5_check "/usr/include/openssl/ssl.h" "19588a1c8a27ab814ab6d52843e36cc1"
md5_check "/usr/include/openssl/ssl3.h" "b9d8d0222a7fba6be5abd77099f6ada2"
md5_check "/usr/src/Makefile.inc1" "e1e184f56d8321b4b3531103864e5ce8"
md5_check "/usr/src/sbin/hastd/pjdlog.c" "991b375cd7c3822ad0d9d7eb133fb601"
md5_check "/usr/src/sys/boot/i386/Makefile.inc" "247c077b00fb21a12d3b576c3436db24"
md5_check "/usr/src/sys/boot/i386/boot2/Makefile" "3e062164e7b28c9b42cb7194e9cc7cd9"
# }}}

patch -p0 < src.patch
assert_cmd "patch -p0 < src.patch"
patch -p0 < makefile_step1.patch
assert_cmd "patch -p0 < makefile_step1.patch"

run_cmd "cp DOG /usr/src/sys/amd64/conf"
cd /usr/src
run_cmd "make clean"
run_cmd "rm -rf /usr/obj/*"
run_cmd "make buildkernel KERNCONF=DOG"
cputs "begin to buildworld step 1"
make buildworld > ~/buildworld_step1.log 2>&1
assert_cmd "make buildworld > ~/buildworld_step1.log 2>&1"
cd $RUN_DIR
patch -p0 -R < makefile_step1.patch
assert_cmd "patch -p0 -R < makefile_step1.patch"

sed -i "" '/CC=/d' /etc/make.conf
assert_cmd "sed -i '' '/CC=/d' /etc/make.conf"
sed -i "" '/CXX=/d' /etc/make.conf
assert_cmd "sed -i '' '/CXX=/d' /etc/make.conf"
patch -p0 < makefile_step2.patch
assert_cmd "patch -p0 < makefile_step2.patch"
cd /usr/src
cputs "begin to buildworld step 2"
make NO_CLEAN=yes buildworld > ~/buildworld_step2.log 2>&1
assert_cmd "make NO_CLEAN=yes buildworld > ~/buildworld_step2.log 2>&1"

cd $RUN_DIR
patch -p0 -R < src.patch
assert_cmd "patch -p0 -R < src.patch"
# vim: foldmethod=marker
