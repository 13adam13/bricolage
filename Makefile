#
# Bricolage Makefile
#
# Supports the following targets:
#
#   all       - default target checks requirements and builds source
#   install   - installs the bricolage system
#   upgrade   - upgrades an existing installation
#   uninstall - uninstalls an existing installation
#   clean     - delete intermediate files
#   dist      - prepare a distrubution from a CVS checkout
#   clone     - create a distribution based on an existing system
#   test      - run non-database changing test suite
#   devtest   - run all tests, including those that change the database
#
# See INSTALL for details.
#

# Set the location of Perl.
PERL = /usr/bin/perl

# can't load Bric since it loads Bric::Config which has dependencies
# that won't be solved till make install.
BRIC_VERSION = `$(PERL) -ne '/VERSION.*?([\d\.]+)/ and print $$1 and exit' < lib/Bric.pm`

#########################
# build rules           #
#########################

all 		: required.db modules.db apache.db postgres.db config.db \
                  bconf/bricolage.conf build_done

required.db	: inst/required.pl
	$(PERL) inst/required.pl

modules.db 	: inst/modules.pl lib/Bric/Admin.pod
	$(PERL) inst/modules.pl

apache.db	: inst/apache.pl required.db
	$(PERL) inst/apache.pl

# This shoudl be updated to something more database-independent. In fact,
# what should happen is that a script should present a list of supported
# databases, the user picks which one (each with a key name for the DBD
# driver, e.g., "Pg", "mysql", "Oracle", etc.), and then the rest of the
# work should just assume that database and do the work for that database.
postgres.db 	: inst/postgres.pl required.db
	$(PERL) inst/postgres.pl

config.db	: inst/config.pl required.db apache.db postgres.db
	$(PERL) inst/config.pl

bconf/bricolage.conf	:  required.db inst/conf.pl
	$(PERL) inst/conf.pl INSTALL $(BRIC_VERSION)

build_done	: required.db modules.db apache.db postgres.db config.db \
                  bconf/bricolage.conf
	@echo
	@echo ===========================================================
	@echo ===========================================================
	@echo 
	@echo Bricolage Build Complete. You may now proceed to
	@echo \"make cpan\", which must be run as root, to install any
	@echo needed Perl modules\; then to
	@echo \"make test\" to run some basic tests of the API\; then to
	@echo \"make install\", which must be run as root.
	@echo 
	@echo ===========================================================
	@echo ===========================================================
	@echo
	@touch build_done

.PHONY 		: all


###########################
# dist rules              #
###########################

dist            : check_dist distclean inst/Pg.sql dist_dir \
                  rm_CVS rm_tmp dist/INSTALL dist/Changes \
                  dist/License dist_tar

check_dist      :
	$(PERL) inst/check_dist.pl $(BRIC_VERSION)

distclean	: clean
	-rm -rf bricolage-$(BRIC_VERSION)
	-rm -f  bricolage-$(BRIC_VERSION).tar.gz
	-rm -f inst/Pg.sql
	-rm -rf dist

dist_dir	:
	-rm -rf dist
	mkdir dist
	ls | grep -v dist | grep -v sql | $(PERL) -lne 'system("cp -pR $$_ dist")'

rm_CVS		:
	find dist/ -type d -name 'CVS' | xargs rm -rf
	find dist/ -name '.cvsignore'  | xargs rm -rf

rm_tmp		:
	find dist/ -name '#*#' -o -name '*~' | xargs rm -rf

dist/INSTALL	: lib/Bric/Admin.pod
	pod2text lib/Bric/Admin.pod   > dist/INSTALL

dist/Changes	: lib/Bric/Changes.pod
	pod2text lib/Bric/Changes.pod > dist/Changes

dist/License	: lib/Bric/License.pod
	pod2text lib/Bric/License.pod > dist/License

dist_tar	:
	mv dist bricolage-$(BRIC_VERSION)
	tar cvf bricolage-$(BRIC_VERSION).tar bricolage-$(BRIC_VERSION)
	gzip --best bricolage-$(BRIC_VERSION).tar

SQL_FILES := $(shell find lib -name '*.sql' -o -name '*.val' -o -name '*.con')

# Update this later to be database-independent.
inst/Pg.sql : $(SQL_FILES)
	find sql/Pg -name '*.sql' -exec grep -v '^--' '{}' ';' >  $@;
	find sql/Pg -name '*.val' -exec grep -v '^--' '{}' ';' >> $@;
	find sql/Pg -name '*.con' -exec grep -v '^--' '{}' ';' >> $@;

.PHONY 		: distclean inst/Pg.sql dist_dir rm_CVS dist_tar check_dist

##########################
# clone rules            #
##########################


clone           : distclean clone.db clone_dist_dir clone_sql clone_files \
		  rm_CVS rm_tmp \
                  dist/INSTALL dist/Changes dist/License \
		  clone_tar 

clone.db	:
	$(PERL) inst/clone.pl

clone_dist_dir  : 
	-rm -rf dist
	mkdir dist

clone_files     :
	$(PERL) inst/clone_files.pl

clone_sql       : 
	$(PERL) inst/clone_sql.pl

clone_tar	:
	$(PERL) inst/clone_tar.pl

.PHONY 		: clone_dist_dir clone_files clone_sql clone_tar

##########################
# installation rules     #
##########################

install 	: all is_root cpan lib bin files db db_grant done

is_root         : inst/is_root.pl
	$(PERL) inst/is_root.pl

cpan 		: modules.db postgres.db inst/cpan.pl
	$(PERL) inst/cpan.pl

lib 		: 
	-rm -f lib/Makefile
	cd lib; $(PERL) Makefile.PL; $(MAKE) install

bin 		:
	-rm -f bin/Makefile
	cd bin; $(PERL) Makefile.PL; $(MAKE) install

files 		: config.db bconf/bricolage.conf
	$(PERL) inst/files.pl

db    		: inst/db.pl postgres.db
	$(PERL) inst/db.pl

db_grant	: inst/db.pl postgres.db
	$(PERL) inst/db_grant.pl

done		: bconf/bricolage.conf db files bin lib cpan
	$(PERL) inst/done.pl

.PHONY 		: install is_root lib bin files db done


##########################
# upgrade rules          #
##########################

upgrade		: upgrade.db required.db bconf/bricolage.conf is_root cpan \
	          stop db_upgrade lib bin  db_grant upgrade_files \
	          upgrade_conf upgrade_done

upgrade.db	: 
	$(PERL) inst/upgrade.pl

db_upgrade	: upgrade.db
	$(PERL) inst/db_upgrade.pl

stop		:
	$(PERL) inst/stop.pl

upgrade_files   :
	$(PERL) inst/files.pl UPGRADE

upgrade_conf    :

	$(PERL) inst/conf.pl UPGRADE $(BRIC_VERSION)

upgrade_done    :
	@echo
	@echo ===========================================================
	@echo ===========================================================
	@echo 
	@echo Bricolage Upgrade Complete.  You may now start your
	@echo servers to start using the new version of Bricolage.
	@echo 
	@echo ===========================================================
	@echo ===========================================================
	@echo

.PHONY		: db_upgrade upgrade_files stop upgrade_done

##########################
# uninstall rules        #
##########################

uninstall 	: is_root prep_uninstall stop db_uninstall rm_files clean

prep_uninstall	:
	$(PERL) inst/uninstall.pl

db_uninstall	:
	$(PERL) inst/db_uninstall.pl

rm_files	:
	$(PERL) inst/rm_files.pl

.PHONY 		: uninstall prep_uninstall db_uninstall rm_files

##########################
# test rules             #
##########################
TEST_VERBOSE=0

test		:
	PERL_DL_NONLAZY=1 $(PERL) inst/runtests.pl

devtest         :
	PERL_DL_NONLAZY=1 $(PERL) inst/runtests.pl -d

##########################
# clean rules            #
##########################

clean 		: 
	-rm -rf *.db
	-rm -rf build_done
	-rm -rf bconf
	cd lib ; $(PERL) Makefile.PL ; $(MAKE) clean
	-rm -rf lib/Makefile.old
	cd bin ; $(PERL) Makefile.PL ; $(MAKE) clean
	-rm -rf bin/Makefile.old

.PHONY 		: clean
