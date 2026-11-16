# BX510 port-2002 client-leg oracles — Firebird (CDSML8558), VM ISO dd
#
# Computed 2026-11-15 on the VM from /home/you/the verification tree/firebird.iso
# (dd bs=2048 skip=LBA count=CNT | md5sum), script /tmp/oracle2.sh +
# /tmp/oracle_toc.py; the 532104x1 row reproduces the recorded
# firebird-fixture.md §8.3 oracle exactly (cross-check PASS).
#
# Area geometry decoded from the ISO (tools-side parse = sacd_ui.c rules):
#   TWOCHTOC @544 (daemon area_1_toc_1): ch=2, 6 tracks,
#       trk_start @72 = 584, trk_end @76 = 353763
#       track 0: start_lsn=745 len=36305
#       track 1: start_lsn=37049 len=52251
#       track 2: start_lsn=89299 len=32567
#       track 3: start_lsn=121865 len=65440
#       track 4: start_lsn=187783 len=73113
#       track 5: start_lsn=261507 len=92257
#   MULCHTOC @353804 (daemon area_2_toc_1): ch=6, 6 tracks,
#       trk_start @72 = 353844, trk_end @76 = 1064126
#       track 0: start_lsn=354316 ... track 5: start_lsn=878724 len=185403
#   => LBA 532104 is inside the MULTICHANNEL area's audio zone, not the
#      2-channel area. The honest "2-channel music sector" targets are
#      745..261507+len (2ch track starts).
#
# | LBA     | cnt  | md5                              | note |
# |---------|------|----------------------------------|------|
# | 510     | 10   | 45ccd7dfbf433a79d28e877d7441677c | Master TOC bundle (recorded oracle) |
# | 16      | 1    | c117ce4cef54ab625e33583156605721 | PVD (recorded) |
# | 532104  | 1    | 9ed18b47f67232ea972515df65cb6ac5 | mid mc-area (recorded, re-derived) |
# | 532104  | 64   | 719c67ed4a853de163b92e4400c37d70 | mc-area audio batch |
# | 532104  | 128  | 8edde68ebb84eaad6623ef1fd5b9958b | mc-area full MAX chunk |
# | 532104  | 256  | 45cf92c871e5adebc5e53d5a43bdafe7 | mc-area 2-chunk batch |
# | 353844  | 16   | f4a7c125f8c09adf7869b88354c09baf | mc-area start (trk_start 353844) |
# | 745     | 128  | 5b5c4f4e411155d46885b5848cefd48d | 2ch track 0 START, full MAX chunk |
# | 845     | 1    | 9079e1fce610663d9f0e50bbd3463e0c | 2ch track 0 music, single |
# | 845     | 16   | 4545b0a28cc6fbf878216beacb661b76 | 2ch track 0 music, 16 |
# | 845     | 32   | 1df16354392e34456e8a11e174140ba5 | 2ch track 0 music, 32 |
# | 845     | 128  | (uncomputed)                     | spare |
# | 353750  | 40   | dffda49fa00fffdaac8c5fddf38a959e | straddles 2ch area end (353763) |
# | 600     | 1600 | 2609c51af8831e3e3c9f1eaaf2ce5449 | long 2ch rip (obs watch) |
# | 1064207 | 1    | d1c54ec6c395d7092ce06f04705d33ae | final sector (recorded) |
# | 1064300 | 4    | (empty: past EOF)                | failure-case probe |
#
# SUPERSESSION NOTES (review 2026-11-15):
# - "LBA 532104 is inside the 2-channel area" in firebird-fixture.md:307 and
#   "mid 2-channel area, branch 2" in daemon-socket-protocol.md:602 are
#   STALE — 532104 is inside the MULTICHANNEL area's audio zone
#   (353844..1064126, MULCHTOC trk_start..trk_end). This table's geometry
#   row is the corrected one.
# - TOC naming: this table labels @353804 'daemon area_2_toc_1' per
#   master-toc-structure.md's field map (0x48 = area_2_toc_1_start = 353804,
#   VERIFIED from the real TOC bytes; the daemon reads the two _toc_1
#   copies, 544 + 353804). firebird-fixture.md s2.6's "353804 =
#   area_1_toc_2_start" label is the stale one. Both MULCHTOC copies carry
#   identical content, so no oracle changes — but cite the master-toc
#   field map, not the fixture section, for the names.
