make clean
export PATH=/usr/local/smlnj/bin:/usr/local:/usr/bin:$PATH
cp src/compiler/backup/codegen/fragments.gmk src/compiler/codegen/fragments.gmk
cp src/compiler/backup/codegen/fragments.sml src/compiler/codegen/fragments.sml
cp src/compiler/backup/cxx-util/fragments.gmk src/compiler/cxx-util/fragments.gmk
cp src/compiler/backup/cxx-util/fragments.sml src/compiler/cxx-util/fragments.sml
cp src/compiler/backup/target-cpu/fragments.gmk src/compiler/target-cpu/fragments.gmk
cp src/compiler/backup/target-cpu/fragments.sml src/compiler/target-cpu/fragments.sml
make clean
make local-install
autoheader -Iconfig
autoconf -Iconfig
./configure --with-teem=/usr/local
make local-install
autoheader -Iconfig
autoconf -Iconfig
./configure --with-teem=/usr/local
make local-install