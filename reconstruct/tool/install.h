/**
 * Module installation for the Mediatek SACD read kernel module.
 *
 * Community port addition ("sacd_extract_160"): extracts the embedded
 * sacd_read.ko (linked in via `ld -b binary`), installs it with insmod
 * and creates the /dev/sacd_read character device node.
 */

#ifndef INSTALL_H_INCLUDED
#define INSTALL_H_INCLUDED

int install_modules(void);
void remove_modules(void);

#endif /* INSTALL_H_INCLUDED */
