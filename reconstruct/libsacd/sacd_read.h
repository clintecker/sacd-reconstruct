/**
 * sacd_read.h - userspace interface of the sacd_read.ko Mediatek kernel
 * module (CPSA SACD copy-protection driver wrappers).
 *
 * Community port addition ("sacd_extract_160").
 */

#ifndef SACD_READ_H_INCLUDED
#define SACD_READ_H_INCLUDED

int init_sacd(void);
int auth_sacd(void);
int read_sacd(int, int, void *);
void uninit_sacd(void);
int decrypt_sacd(int, void *);
int disc_sacd(void);
int sacd_sacd(void);

#endif /* SACD_READ_H_INCLUDED */
