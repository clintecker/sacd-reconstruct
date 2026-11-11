#!/bin/sh
# kcheck.sh — staged guest-side symbol-export check (Run C43+).
# One line per symbol; long one-liners get truncated by the guest shell.
grep -wq __kmalloc /res/proc/kallsyms && echo KEXP-__kmalloc=yes || echo KEXP-__kmalloc=no
grep -wq __get_free_pages /res/proc/kallsyms && echo KEXP-__get_free_pages=yes || echo KEXP-__get_free_pages=no
grep -wq __copy_from_user /res/proc/kallsyms && echo KEXP-__copy_from_user=yes || echo KEXP-__copy_from_user=no
grep -wq __copy_to_user /res/proc/kallsyms && echo KEXP-__copy_to_user=yes || echo KEXP-__copy_to_user=no
grep -wq __create_workqueue_key /res/proc/kallsyms && echo KEXP-__create_workqueue_key=yes || echo KEXP-__create_workqueue_key=no
grep -wq __aeabi_idiv /res/proc/kallsyms && echo KEXP-__aeabi_idiv=yes || echo KEXP-__aeabi_idiv=no
grep -wq ___ratelimit /res/proc/kallsyms && echo KEXP-___ratelimit=yes || echo KEXP-___ratelimit=no
grep -wq __bug /res/proc/kallsyms && echo KEXP-__bug=yes || echo KEXP-__bug=no
grep -wq blk_execute_rq /res/proc/kallsyms && echo KEXP-blk_execute_rq=yes || echo KEXP-blk_execute_rq=no
grep -wq blk_get_request /res/proc/kallsyms && echo KEXP-blk_get_request=yes || echo KEXP-blk_get_request=no
grep -wq blk_put_request /res/proc/kallsyms && echo KEXP-blk_put_request=yes || echo KEXP-blk_put_request=no
grep -wq blk_rq_map_user /res/proc/kallsyms && echo KEXP-blk_rq_map_user=yes || echo KEXP-blk_rq_map_user=no
grep -wq add_disk /res/proc/kallsyms && echo KEXP-add_disk=yes || echo KEXP-add_disk=no
grep -wq alloc_disk /res/proc/kallsyms && echo KEXP-alloc_disk=yes || echo KEXP-alloc_disk=no
grep -wq scsi_execute_req /res/proc/kallsyms && echo KEXP-scsi_execute_req=yes || echo KEXP-scsi_execute_req=no
grep -wq scsi_add_device /res/proc/kallsyms && echo KEXP-scsi_add_device=yes || echo KEXP-scsi_add_device=no
grep -wq scsi_host_alloc /res/proc/kallsyms && echo KEXP-scsi_host_alloc=yes || echo KEXP-scsi_host_alloc=no
grep -wq scsi_register /res/proc/kallsyms && echo KEXP-scsi_register=yes || echo KEXP-scsi_register=no
grep -wq BSP_CleanDCacheRange /res/proc/kallsyms && echo KEXP-BSP_CleanDCacheRange=yes || echo KEXP-BSP_CleanDCacheRange=no
grep -wq BSP_FlushDCacheRange /res/proc/kallsyms && echo KEXP-BSP_FlushDCacheRange=yes || echo KEXP-BSP_FlushDCacheRange=no
grep -wq BSP_InvDCacheRange /res/proc/kallsyms && echo KEXP-BSP_InvDCacheRange=yes || echo KEXP-BSP_InvDCacheRange=no
grep -wq Ethernet_resume /res/proc/kallsyms && echo KEXP-Ethernet_resume=yes || echo KEXP-Ethernet_resume=no
grep -wq _fg_fe_bootup /res/proc/kallsyms && echo KEXP-_fg_fe_bootup=yes || echo KEXP-_fg_fe_bootup=no
grep -wq sata_int_ldr_fw /res/proc/kallsyms && echo KEXP-sata_int_ldr_fw=yes || echo KEXP-sata_int_ldr_fw=no
grep -wq sata_hw_seg_buf /res/proc/kallsyms && echo KEXP-sata_hw_seg_buf=yes || echo KEXP-sata_hw_seg_buf=no
grep -wq mt85xx_fefwmem_base /res/proc/kallsyms && echo KEXP-mt85xx_fefwmem_base=yes || echo KEXP-mt85xx_fefwmem_base=no
grep -wq mt85xx_svoif_reserve_base /res/proc/kallsyms && echo KEXP-mt85xx_svoif_reserve_base=yes || echo KEXP-mt85xx_svoif_reserve_base=no
grep -wq ide_log_en /res/proc/kallsyms && echo KEXP-ide_log_en=yes || echo KEXP-ide_log_en=no
grep -wq SR_LOG_Level /res/proc/kallsyms && echo KEXP-SR_LOG_Level=yes || echo KEXP-SR_LOG_Level=no
grep -wq cdrom_log_en /res/proc/kallsyms && echo KEXP-cdrom_log_en=yes || echo KEXP-cdrom_log_en=no
grep -wq sys_open /res/proc/kallsyms && echo KEXP-sys_open=yes || echo KEXP-sys_open=no
grep -wq sys_ioctl /res/proc/kallsyms && echo KEXP-sys_ioctl=yes || echo KEXP-sys_ioctl=no
grep -wq sys_mknod /res/proc/kallsyms && echo KEXP-sys_mknod=yes || echo KEXP-sys_mknod=no
grep -wq sata_mtd_read_buf /res/proc/kallsyms && echo KEXP-sata_mtd_read_buf=yes || echo KEXP-sata_mtd_read_buf=no
grep -wq svoif_int_ldr_dram_sz /res/proc/kallsyms && echo KEXP-svoif_int_ldr_dram_sz=yes || echo KEXP-svoif_int_ldr_dram_sz=no
grep -wq mt85xx_svoif_reserve_base_remap /res/proc/kallsyms && echo KEXP-mt85xx_svoif_reserve_base_remap=yes || echo KEXP-mt85xx_svoif_reserve_base_remap=no
grep -wq _sata_tray_status /res/proc/kallsyms && echo KEXP-_sata_tray_status=yes || echo KEXP-_sata_tray_status=no
grep -wq fgFL_ChkSinfo4Reg /res/proc/kallsyms && echo KEXP-fgFL_ChkSinfo4Reg=yes || echo KEXP-fgFL_ChkSinfo4Reg=no
grep -wq vFL_SetSinfo4Reg /res/proc/kallsyms && echo KEXP-vFL_SetSinfo4Reg=yes || echo KEXP-vFL_SetSinfo4Reg=no
grep -wq cpu_cache /res/proc/kallsyms && echo KEXP-cpu_cache=yes || echo KEXP-cpu_cache=no
grep -wq mem_map /res/proc/kallsyms && echo KEXP-mem_map=yes || echo KEXP-mem_map=no
grep -wq print_err_log /res/proc/kallsyms && echo KEXP-print_err_log=yes || echo KEXP-print_err_log=no
echo KEXP2_DONE
# CLI framework symbol dump (module bss globals)
grep -E 'pt_cur|e_access|_cmd_tbl|grp_info' /res/proc/kallsyms; echo CLI_SYM_DONE
echo KEXP2_DONE
