$       ! Packaging OpenSSL into an install kit
$       !
$       ! P1 - OpenSSL source directory
$       !
$       ! This command procedure will create two subdirectories,
$       ! [._build_'arch'] and [._kit_'arch'].  [._build_'arch']
$	! is used for OpenSSL builds, and [._kit_'arch'] is used
$	! to build up the final kit.
$
$       ! Find the architecture
$       IF F$GETSYI("CPU") .LT. 128
$       THEN
$           arch := VAX
$       ELSE
$           arch = F$EDIT(F$GETSYI("ARCH_NAME"),"UPCASE")
$           IF arch .EQS. "" THEN GOTO unknown_arch
$       ENDIF
$       name_Alpha := AXPVMS
$       name_IA64  := I64VMS
$       name_VAX   := VAXVMS
$       arch = name_'arch'
$
$       ON ERROR THEN GOTO end
$       ON CONTROL_Y THEN GOTO end
$
$       source = F$PARSE("A.;", P1, "[]") - "]A.;"
$       here = F$ENVIRONMENT("DEFAULT") - "]"
$
$       SET DEFAULT 'source']
$       SET DEFAULT [.util]
$       util = F$ENVIRONMENT("DEFAULT") - "]"
$       SET DEFAULT 'here']
$
$       CREATE/DIR [._build_'arch']
$       CREATE/DIR [._kit_'arch']
$       CREATE/DIR [._kit_'arch'.files]
$
$       SET DEFAULT [._kit_'arch']
$       kit = F$ENVIRONMENT("DEFAULT") - "]"
$
$       SET DEFAULT [-._build_'arch']
$       build = F$ENVIRONMENT("DEFAULT")
$
$       @'source']config -32 shared
$       MMS build_libs,install_dev /mac=destdir='kit'.files]
$
$       MMS clean
$       @'source']config -64 shared
$       MMS build_libs,install_dev /mac=destdir='kit'.files]
$
$       MMS clean
$       @'source']config shared
$       MMS all,install /mac=destdir='kit'.files]
$
$       purge 'kit'.files...]*.*
$
$       SET DEFAULT [-]
$       perl "-I_build_''arch'" "-Mconfigdata" 'source'.util]dofile.pl -
             openssl.pcsi$desc-in > [._kit_'arch']openssl.pcsi$desc
$       perl "-I_build_''arch'" "-Mconfigdata" 'source'.util]dofile.pl -
             openssl.pcsi$text-in > [._kit_'arch']openssl.pcsi$text
$       perl "-I_build_''arch'" "-Mconfigdata" 'source'.util]dofile.pl -
             ossl$startup.com.in > [._kit_'arch'.files]ossl$startup.com
$       perl "-I_build_''arch'" "-Mconfigdata" 'source'.util]dofile.pl -
             ossl$utils.com.in > [._kit_'arch'.files]ossl$utils.com
$       perl "-I_build_''arch'" "-Mconfigdata" 'source'.util]dofile.pl -
             ossl$shutdown.com.in > [._kit_'arch'.files]ossl$shutdown.com
$       perl "-I_build_''arch'" "-Mconfigdata" 'source'.util]dofile.pl -
             ossl$ivp.com.in > [._kit_'arch'.files]ossl$ivp.com
$
$       PRODUCT PACKAGE OpenSSL -
                /BASE='arch' -
                /PRODUCER=Levitte -
                /SOURCE=[._kit_'arch']openssl -
                /DESTINATION=[._kit_'arch'] -
                /MATERIAL=([._kit_'arch'.files...]) -
                /FORMAT=SEQUENTIAL
$
$ end:
$       SET DEFAULT 'here']
