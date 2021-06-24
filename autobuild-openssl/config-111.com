$	build_downloaddir       :== program:[levitte-builds.downloads]
$	build_builddir          :== program:[levitte-builds.openssl111]
$	build_installdir        :== program:[levitte-builds._install111]
$	build_openssldir        :== program:[levitte-builds._common]
$	build_report_recipient   == "levitte@openssl.org"
$
$!	build_hosts             :== JULIA ALIKGB
$	build_hosts             :== ANGELA ALIKGB
$	build_config0            == "no-shared"
$	build_config1            == ""
$	build_config2            == "-32"
$	build_config3            == "-64"
$
$	build_queue_ANGELA      :== angela_batch
$	build_queue_JULIA       :== julia_batch
$	build_queue_ALIKGB      :== alikgb_batch
$
$	build_queue_MAIL        :== angela_batch
$	build_queue_DISPATCH    :== angela_batch
$
$	build_snapshot_prefix    == "openssl-1.1.1-stable-SNAP-"
$
$	build_precmd            :== set proc/priv=(noall,tmpmbx,netmbx,exquota)
$	build_cmd0               == "@'sourcedir'config 'configopts' --prefix='installdir' --openssldir='openssldir'"
$
$	build_cmd1              :== mms
$	build_cmd2              :== mms test
$	build_cmd3              :== mms install
$	build_cmd4              :== mms check_install
