$	build_downloaddir       :== program:[levitte-builds.downloads]
$	build_builddir          :== program:[levitte-builds.openssl30]
$	build_installdir        :== program:[levitte-builds._install30]
$	build_openssldir        :== program:[levitte-builds._common30]
$	build_report_recipient   == "levitte@openssl.org"
$
$!	build_hosts             :== JULIA ALICIA ALIKGB
$	build_hosts             :== ANGELA ALICIA ALIKGB
$	build_config0            == "no-shared"
$	build_config1            == ""
$	build_config2            == "vms-''arch'-P32"
$	build_config3            == "vms-''arch'-P64"
$	build_config4            == "enable-fips"
$
$	build_queue_ANGELA      :== angela_batch
$	build_queue_JULIA       :== julia_batch
$	build_queue_ALICIA      :== alicia_batch
$	build_queue_ALIKGB      :== alikgb_batch
$
$	build_queue_MAIL        :== angela_batch
$	build_queue_DISPATCH    :== angela_batch
$
$	build_snapshot_prefix    == "openssl-3.0-SNAP-"
$
$	build_precmd            :== set proc/priv=(noall,tmpmbx,netmbx,exquota)
$	build_cmd0               == "perl 'sourcedir'Configure 'configopts' --prefix='installdir' --openssldir='openssldir'"
$
$	build_cmd1              :== mms
$	build_cmd2              :== mms test
$	build_cmd3              :== mms install
$	build_cmd4              :== mms check_install
