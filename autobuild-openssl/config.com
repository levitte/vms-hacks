$	build_downloaddir       :== program:[levitte-builds.downloads]
$	build_builddir          :== program:[levitte-builds.openssl]
$	build_installdir        :== program:[levitte-builds._install]
$	build_openssldir        :== program:[levitte-builds._common]
$	build_report_recipient   == "levitte@openssl.org"
$
$	build_platforms         :== ALPHA IA64
$	build_config0            == "no-shared"
$	build_config1            == ""
$	build_config2            == "-32"
$	build_config3            == "-64"
$
$	build_queue_ALPHA       :== julia_batch
$	build_queue_IA64        :== alikgb_batch
$
$	build_queue_MAIL        :== angela_batch
$	build_queue_DISPATCH    :== angela_batch
$
$	build_snapshot_prefix    == "openssl-SNAP-"
$
$	build_precmd            :== set proc/priv=(noall,tmpmbx,netmbx,exquota)
$	build_cmd0               == "@'sourcedir'config 'configopts' --prefix='installdir' --openssldir='openssldir'"
$
$	build_cmd1              :== mms
$	build_cmd2              :== mms test
$	build_cmd3              :== mms install
$	build_cmd4              :== mms check_install
