# Makefile for regpg
#
# You may do anything with this. It has no warranty.
# <https://creativecommons.org/publicdomain/zero/1.0/>

.POSIX:

prefix =	${HOME}
bindir =	${prefix}/bin
mandir =	${prefix}/share/man
man1dir=	${mandir}/man1

bindest=	${DESTDIR}${bindir}
man1dest=	${DESTDIR}${man1dir}

markdown=	doc/contributing.md	\
		doc/rationale.md	\
		doc/relnotes.md		\
		doc/secrets.md		\
		doc/threat-model.md	\
		doc/tutorial.md		\
		README.md

htmlfiles=	regpg.html ${markdown:.md=.html}
man1files=	regpg.1

DOCS=		${htmlfiles} ${man1files}

ansible=	ansible/action.py	\
		ansible/filter.py	\
		ansible/gpg-preload.yml	\
		ansible/vault-open.sh

PROGS=		regpg

ALL=		${PROGS} ${DOCS}

all: ${ALL}

install: all
	install -m 755 -d ${bindest}
	install -m 755 ${PROGS} ${bindest}/
	install -m 755 -d ${man1dest}
	install -m 644 ${man1files} ${man1dest}/

uninstall:
	for f in ${PROGS}; do rm -f ${bindest}/$$f; done
	for f in ${man1files}; do rm -f ${man1dest}/$$f; done

clean:
	rm -f ${ALL} regpg.asc index.html
	rm -rf t/bin t/gnupg r/regpg t/work

test: ${PROGS}
	util/test.pl

regpg: regpg.pl ${ansible}
	util/insert-here.pl <regpg.pl >regpg
	chmod +x regpg

regpg.1: regpg
	pod2man regpg regpg.1

regpg.html: regpg
	pod2html --noindex --css=doc/style.css \
		--title 'regpg reference manual' \
		regpg >regpg.html
	rm -f pod2htm?.tmp

index.html: README.html logo/iframe.pl
	logo/iframe.pl <README.html >index.html

.SUFFIXES: .md .html

.md.html:
	util/markdown.pl $< $@

release: all
	util/release.sh ${ALL}

uptalk:
	for subdir in talks/*; do ${MAKE} -C $$subdir all tidy; done

upload: ${ALL} index.html uptalk
	util/upload.sh
