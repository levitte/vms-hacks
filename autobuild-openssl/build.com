$	save_ver = f$verify(0) ! change to 1 to get command verification
$	here = f$environment("DEFAULT")
$	this = f$environment("PROCEDURE")
$	thislog = f$parse(".LOG;",this) - ";"
$
$	! Set up defaults
$
$	configname = P1
$	if configname .eqs. "" then configname := CONFIG
$	configfile = f$parse("''configname';",this,,,"SYNTAX_ONLY") - ";"
$	@'configfile'
$
$	if f$mode() .nes. "BATCH" then goto bootstrap
$
$	on error then goto bootstrap
$
$	! Possible states are: START, CONFIG, BUILD, TEST, INSTALL, REPORT
$	state = P3
$	if state .eqs. "" then goto exit
$	goto 'state'
$
$ START:
$	define/user PERL_ENV_TABLES CLISYM_LOCAL
$	perl -e "(my $prefix_us = $ARGV[0]) =~ s|\.|_|g; $ENV{BUILD_SNAPSHOT_PREFIX_US} = $prefix_us" "''build_snapshot_prefix'"
$	set default 'build_downloaddir'
$	loop0:
$	    d = f$search("''build_snapshot_prefix_us'*.DIR",1)
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
use strict;
my $build_snapshot_prefix = $ARGV[0];
my @lines =
    sort
    map { chomp; s|^.*>(${build_snapshot_prefix}(\d+))\.tar\.gz<.*$|$1|; $_ }
    (grep m|>(${build_snapshot_prefix}(\d+))\.tar\.gz<|, (<STDIN>));
my $snapshot_name = pop @lines;
(my $snapshot_name_us = $snapshot_name) =~ s|\.|_|g;

# This is a trick that sets a local DCL symbol
# if PERL_ENV_TABLES is defined to "CLISYM_LOCAL"
$ENV{NAME} = $snapshot_name;
$ENV{NAME_US} = $snapshot_name_us;
$EOD
$	define/user PERL_ENV_TABLES CLISYM_LOCAL
$	perl openssl-listing-'pid'.pl "''build_snapshot_prefix'" < openssl-listing-'pid'.html
$	
$	delete openssl-listing-'pid'.pl;*
$	delete openssl-listing-'pid'.html;*
$
$	wget "-O" "''name_us'.tar-gz" "http://ftp.openssl.org/snapshot/''name'.tar.gz"
$
$	gzip -f -d "''name_us'.tar-gz"
$	tar -xvf "''name_us'.tar"
$
$	delete 'name_us'.tar;*
$
$	set default [.'name_us']
$	sourcedir = f$environment("default")
$
$	host_i = 0
$	loop1:
$	    host = f$element(host_i, " ", build_hosts)
$	    host_i = host_i + 1
$	    if host .eqs. " " then goto endloop1
$	    queue = build_queue_'host'
$	    confignum = 0
$	    loop2:
$		if f$type(build_config'confignum') .eqs. "" then goto endloop2
$
$		gosub setvars
$
$		set noon
$
$		if builddir .nes. ""
$		then
$		    set default 'builddir'
$		    create/dir []
$		    delete/log/tree [...]*.*;*
$		    if f$type(build_copysource) .nes. ""
$		    then
$			sourcetree = sourcedir - "]" + "...]"
$			copy/log 'sourcetree'*.* [...]
$		    endif
$		endif
$
$		if installdir .nes. ""
$		then
$		    set default 'installdir'
$		    create/dir []
$		    delete/log/tree [...]*.*;*
$		endif
$
$		if openssldir .nes. ""
$		then
$		    set default 'openssldir'
$		    create/dir []
$		    delete/log/tree [...]*.*;*
$		endif
$
$		open/write log 'logfile'
$		close log
$
$		set on
$
$		submit 'this' /queue='queue' /log='thislog' -
		       /para=('configname','queue',EXECUTE,0,-
			      'host','confignum','sourcedir')
$		confignum = confignum + 1
$		goto loop2
$	    endloop2:
$	    goto loop1
$	endloop1:
$
$	goto bootstrap
$	
$ REPORT: 
$	! P4	log file
$	! P5	subject
$	mail 'P4' "''build_report_recipient'" /subject="''P5'"
$	goto exit
$	
$ EXECUTE:
$	set noon
$
$	queue = p2
$	state = p3
$	commandnum = p4
$	host = p5
$	confignum = p6
$	sourcedir = p7
$	gosub setvars
$
$	execline = build_cmd'commandnum'
$	if f$type(build_precmd) .nes. "" -
	   then execline = build_precmd + " ; " + execline
$	if f$type(build_postcmd) .nes. "" -
	   then execline = execline + " ; " + build_postcmd
$	if f$type(build_precmd) .nes. "" .or. f$type(build_postcmd) .nes. "" -
	   then execline = "pipe ( " + execline + " )"
$	execline := 'execline'
$
$	! DEBUG (visible when running with SET VERIFY):
$	sourcedir_debug  := 'sourcedir'
$	builddir_debug   := 'builddir'
$	installdir_debug := 'installdir'
$	openssldir_debug := 'openssldir'
$	logfile_debug    := 'logfile'
$	queue_debug      := 'queue'
$	state_debug      := 'state'
$	commandnum_debug := 'commandnum'
$	host_debug       := 'host'
$	confignum_debug  := 'confignum'
$	consigopts_debug := 'configopts'
$	execline_debug   := 'execline'
$
$	commandnum = commandnum + 1
$	if f$type(build_cmd'commandnum') .eqs. ""
$	then
$	    report_state := SUCCESS
$	    next_state := REPORT
$	else
$	    next_state := EXECUTE
$	endif
$
$	if execline .nes. ""
$	then
$	    set default 'builddir'
$	    open/append/share=read log 'logfile'
$
$	    write log "$ ",execline
$	    spawn/wait/out=spawn.log 'execline'
$	    sev = $severity
$	    type spawn.log /output=log
$	    delete spawn.log;*
$
$	    close log
$
$	    set on
$
$	    if (sev .and. 1) .ne. 1
$	    then
$		report_state := FAILURE
$		next_state := REPORT
$	    endif
$	endif
$
$ next_state:
$	set default 'here'
$	if next_state .eqs. "REPORT"
$	then
$	    submit 'this' /queue='build_queue_MAIL' /log='thislog' -
		   /para=('configname','queue',REPORT,'logfile',"''report_state': OpenSSL build of ''name' on ''arch' with config: ''configopts'")
$	else
$	    submit 'this' /queue='queue' /log='thislog' -
		   /para=('configname','queue',EXECUTE,'commandnum',-
			  'host','confignum','sourcedir')
$	endif
$	goto exit
$
$ bootstrap:
$	set default 'here'
$	submit 'this' /queue='build_queue_DISPATCH' /log='thislog' -
	       /para=('configname','build_queue_DISPATCH',START) -
	       /after="tomorrow+09:00"
$	goto exit
$
$ exit:
$	exit !'f$verify(save_ver)
$
$ setvars:
$	set default 'build_builddir'
$	set default [.'host'.config'confignum']
$	builddir = f$environment("default")
$
$	if "''build_installdir'" .nes. ""
$	then
$	    set default 'build_installdir'
$	    set default [.'host'.config'confignum']
$	    installdir = f$environment("default")
$	else
$	    installdir :=
$	endif
$
$	if "''build_openssldir'" .nes. ""
$	then
$	    set default 'build_openssldir'
$	    set default [.'host'.config'confignum']
$	    openssldir = f$environment("default")
$	else
$	    openssldir :=
$	endif
$
$	if "''build_builddir'" .nes. ""
$	then
$	    logfile := 'build_builddir''host'_config'confignum'.log
$	else
$	    logfile := 'sourcedir''host'_config'confignum'.log
$	endif
$
$	configopts = build_config'confignum'
$
$	return
