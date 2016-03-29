$
$	here = f$environment("DEFAULT")
$	this = f$environment("PROCEDURE")
$
$	! Set up defaults
$
$	configfile = f$parse("CONFIG.COM",this,,,"SYNTAX_ONLY")
$	@'configfile'
$
$	if f$mode() .nes. "BATCH" then goto exit
$
$	on error then goto exit
$
$	! Possible states are: START, CONFIG, BUILD, TEST, INSTALL, REPORT
$	build_queue = P1
$	build_state = P2
$	goto 'build_state'
$
$ START:
$	set default 'build_downloaddir'
$	loop0:
$	    d = f$search("openssl-SNAP-*.DIR",1)
$	    if d .eqs. "" then goto endloop0
$	    d = f$parse(d,,,"NAME")
$	    delete/log/tree [.'d'...]*.*;*
$	    set security/prot=(o:d) 'd'.DIR
$	    delete/log 'd'.DIR;
$	    goto loop0
$	endloop0:
$
$	pid = f$getjpi("","PID")
$	wget "-O" openssl-listing-'pid'.html http://ftp.openssl.org/snapshot/
$
$	create openssl-listing-'pid'.pl
$	DECK
my @lines =
    sort
    map { chomp; s|^.*>(openssl-SNAP-(\d+)\.tar\.gz)<.*$|$1|; $_ }
    (grep m|>(openssl-SNAP-(\d+)\.tar\.gz)<|, (<STDIN>));

# This is a trick that sets a local DCL symbol
# if PERL_ENV_TABLES is defined to "CLISYM_LOCAL"
$ENV{NAME} = pop @lines;
$EOD
$	define/user PERL_ENV_TABLES CLISYM_LOCAL
$	perl openssl-listing-'pid'.pl name < openssl-listing-'pid'.html
$	
$	delete openssl-listing-'pid'.pl;*
$	delete openssl-listing-'pid'.html;*
$
$	odir = name - ".tar.gz"
$	oname = odir + ".tar-gz"
$	wget "-O" "''oname'" "http://ftp.openssl.org/snapshot/''name'"
$
$	gzip -d "''oname'"
$	oname = oname - "-gz"
$	tar -xvf "''oname'"
$
$	delete 'oname';*
$
$	set default [.'odir']
$	srcdir = f$environment("default")
$
$	platform_i = 0
$	loop1:
$	    platform = f$element(platform_i, " ", build_platforms)
$	    platform_i = platform_i + 1
$	    if platform .eqs. " " then goto endloop1
$	    queue = build_queue_'platform'
$	    confignum = 0
$	    loop2:
$		if f$type(build_config'confignum') .eqs. "" then goto endloop2
$		config = build_config'confignum'
$
$		set default 'build_builddir'
$		set default [.'platform'.config'confignum']
$		builddir = f$environment("default")
$
$		set default 'build_installdir'
$		set default [.'platform'.config'confignum']
$		instdir = f$environment("default")
$
$		logfile := 'build_builddir''platform'_config'confignum'.log
$		set noon
$		create/dir 'build_builddir'
$		open/write log 'logfile'
$		close log
$		purge 'logfile'
$		set on
$
$		submit 'this' /queue='queue' -
		       /para=('queue',-
			      "CONFIG",'srcdir','builddir','instdir','logfile',-
			      "''config'")
$		confignum = confignum + 1
$		goto loop2
$	    endloop2:
$	    goto loop1
$	endloop1:
$
$	goto exit
$	
$ CONFIG:
$	! P3	source dir
$	! P4	build dir
$	! P5	install dir
$	! P6	log file
$	! P7	config arguments
$	builddir_pref = p4 - "]"
$	instdir_pref = p5 - "]"
$	set noon
$	create/dir 'builddir_pref']
$	delete/log/tree 'builddir_pref'...]*.*;*
$	create/dir 'instdir_pref']
$	delete/log/tree 'instdir_pref'...]*.*;*
$
$	execute_line := @'p3'config 'p7'
$	next_state := BUILD
$	goto execute
$
$ BUILD: 
$	! P3	source dir
$	! P4	build dir
$	! P5	install dir
$	! P6	log file
$	! P7	config arguments
$	execute_line := mms
$	next_state := TEST
$	goto execute
$
$ TEST:	
$	! P3	source dir
$	! P4	build dir
$	! P5	install dir
$	! P6	log file
$	! P7	config arguments
$	execute_line := mms test
$	next_state := INSTALL
$	goto execute
$
$ INSTALL: 
$	! P3	source dir
$	! P4	build dir
$	! P5	install dir
$	! P6	log file
$	! P7	config arguments
$	execute_line := mms/macro=("""DESTDIR"""='P5') install
$	report_state := SUCCESS
$	next_state := REPORT
$	goto execute
$
$ REPORT: 
$	! P3	log file
$	! P4	subject
$	mail 'P3' "''build_report_recipient'" /subject="''P4'"
$	exit
$	
$ execute:
$	set noon
$
$	set default 'P4'
$	open/append/share=read log 'P6'
$
$	write log "$ ''execute_line'"
$	spawn/wait/out=spawn.log 'execute_line'
$	sev = $severity
$	type spawn.log /output=log
$	delete spawn.log;*
$
$	close log
$
$	set on
$
$	if (sev .and. 1) .ne. 1
$	then
$	    report_state := FAILURE
$	    next_state := REPORT
$	endif
$
$ next_state:
$	set default 'here'
$	if next_state .eqs. "REPORT"
$	then
$	    submit 'this' /queue='build_queue_MAIL' -
		   /para=('P1','next_state','P6',"''report_state': OpenSSL build of ''name' on ''arch' with config: ''P7'")
$	else
$	    submit 'this' /queue='P1' -
		   /para=('P1','next_state',"''P3'","''P4'",-
			  "''P5'","''P6'","''P7'","''P8'")
$	endif
$	exit
$
$ exit:
$	set default 'here'
$	submit 'this' /queue='build_queue_DISPATCH'/after="tomorrow+08:00" -
	       /para=('build_queue_DISPATCH',START)
$	exit
