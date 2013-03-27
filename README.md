Build FreeBSD Using GCC 4.6.x/4.7
=================================

Due to GPLV3, FreeBSD is released with GCC 4.2.1 in recent years, as we know that we can build FreeBSD throught latest CLang, but the performance is poorer than compiled from GCC.

Ignoring the licence of GPLV3, we build FreeBSD from scratch by latest GCC by ourselves. However, there are still some codes need to be changed due to the changes and compatibles of GCC on FreeBSD.

That's why I wrote these scripts, you just need run buildenv.sh to compile the whole world.

I have tested the FreeBSD(9.0) compiled by GCC 4.6.3 for half a year under heavy IO (ZFS file system) and CPU load. Nonetheless, there are some suck hacks in this solution to build the world.
