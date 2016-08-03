$	build_downloaddir     :== user:[levitte.downloads]
$	build_builddir        :== program:[levitte-builds.openssl]
$	build_installdir      :== program:[levitte-builds._install]
$	build_openssldir      :== program:[levitte-builds._common]
$	build_report_recipient == "levitte@openssl.org"
$
$	build_platforms       :== ALPHA IA64
$	build_config0         :== no-shared
$	build_config1         :==
$	build_config2         :== -32
$	build_config3         :== -64
$
$	build_queue_ALPHA     :== julia_batch
$	build_queue_IA64      :== alicia_batch
$
$	build_queue_MAIL      :== angela_batch
$	build_queue_DISPATCH  :== angela_batch
