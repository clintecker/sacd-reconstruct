/* Keep regular and PLT relocations together for the vintage ARM dynamic loader. */
SECTIONS {
    .rel.dyn : { *(.rel.dyn) }
    .rel.plt : { *(.rel.plt) }
} INSERT BEFORE .ARM.exidx;
