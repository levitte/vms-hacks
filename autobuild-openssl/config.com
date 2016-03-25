$	build_downloaddir     :== user:[levitte.downloads]
$	build_builddir        :== program:[levitte-builds.openssl]
$	build_installdir      :== program:[levitte-builds._install]
$	build_report_recipient == "levitte@openssl.org"
$
$	build_platforms       :== ALPHA IA64
$	build_config0         :==
$	build_config1         :== shared
$	build_config2         :== -32 shared
$	build_config3         :== -64 shared
$
$	build_queue_ALPHA     :== julia_batch
$	build_queue_IA64      :== alicia_batch
$
$	build_queue_MAIL      :== angela_batch
$	build_queue_DISPATCH  :== angela_batch
