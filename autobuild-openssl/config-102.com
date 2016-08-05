$	build_downloaddir       :== program:[levitte-builds.downloads]
$	build_builddir          :== program:[levitte-builds.openssl102]
$	build_installdir        :== program:[levitte-builds._install102]
$	build_report_recipient   == "levitte@openssl.org"
$
$	build_copysource	:== YES
$	build_platforms         :== ALPHA IA64
$	build_config0            == """"""""""""""
$	build_config1           :== 32
$	build_config2           :== 64
$
$	build_queue_ALPHA       :== julia_batch
$	build_queue_IA64        :== alicia_batch
$
$	build_queue_MAIL        :== angela_batch
$	build_queue_DISPATCH    :== angela_batch
$
$	build_snapshot_prefix    == "openssl-1.0.2-stable-SNAP-"
$
$	build_cmd0               == "@makevms all 'configopts' nodebug"
$	build_cmd1              :== @[.test]tests
$	build_cmd2               == "@install 'installdir' 'configopts'"
