/**
 * SACD Ripper - http://code.google.com/p/sacd-ripper/
 *
 * Copyright (c) 2010-2011 by respective authors.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 */

/* Reconstructed community port ("sacd_extract_160"): the PS3 SAC accessor
 * backend is replaced by the sacd_read.ko CPSA ioctl wrappers and a
 * 64-bit sector read path is added.
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <string.h>
#include <errno.h>
#include <sys/stat.h>
#include <sys/ioctl.h>


#include <utils.h>
#include <logging.h>
#include <socket.h>
#include <pb.h>
#include <pb_encode.h>
#include <pb_decode.h>

#include "scarletbook.h"
#include "sacd_input.h"
#include "sacd_read.h"
#include "sacd_pb_stream.h"
#include "sacd_ripper.pb.h"

#ifndef BLKGETSIZE64
#define BLKGETSIZE64 0x80041272 /* _IOR(0x12,114,4) */
#endif

sacd_input_t (*sacd_input_open)         (const char *);
int          (*sacd_input_close)        (sacd_input_t);
ssize_t      (*sacd_input_read)         (sacd_input_t, int, int, void *);
int          (*sacd_input_read64)       (sacd_input_t, int, int, void *);
char *       (*sacd_input_error)        (sacd_input_t);
int          (*sacd_input_authenticate) (sacd_input_t);
int          (*sacd_input_decrypt)      (sacd_input_t, uint8_t *, int);
uint32_t     (*sacd_input_total_sectors)(sacd_input_t);

struct sacd_input_s
{
    int                 fd;
    uint8_t            *input_buffer;
};

static int sacd_dev_input_read64(sacd_input_t dev, int pos, int blocks, void *buffer);

static int sacd_dev_input_authenticate(sacd_input_t dev)
{
    int result = auth_sacd();
    if (result < 0)
    {
        LOG(lm_main, LOG_ERROR, ("auth_sacd (%#x)\n", result));
        return result;
    }
    return 0;
}

static int sacd_dev_input_decrypt(sacd_input_t dev, uint8_t *buffer, int blocks)
{
    int result = decrypt_sacd(blocks, buffer);
    if (result < 0)
    {
        LOG(lm_main, LOG_ERROR, ("decrypt_sacd: (%#x)\n", result));
        return -1;
    }
    return 0;
}

/**
 * initialize and open a SACD device or file.
 */
static sacd_input_t sacd_dev_input_open(const char *target)
{
    sacd_input_t dev;

    /* Allocate the library structure */
    dev = (sacd_input_t) calloc(sizeof(*dev), 1);
    if (dev == NULL)
    {
        fprintf(stderr, "libsacdread: Could not allocate memory.\n");
        return NULL;
    }

    /* Open the device */
    dev->fd = open64(target, O_RDONLY);

    if (dev->fd < 0)
        goto fail;

    if (sacd_input_read64 == sacd_dev_input_read64)
    {
        if (init_sacd() < 0)
        {
            close(dev->fd);
            goto fail;
        }
    }
    return dev;

fail:

    free(dev);

    return 0;
}

/**
 * return the last error message
 */
static char *sacd_dev_input_error(sacd_input_t dev)
{
    /* use strerror(errno)? */
    return (char *) "unknown error";
}

/**
 * read data from the device.
 */
static ssize_t sacd_dev_input_read(sacd_input_t dev, int pos, int blocks, void *buffer)
{
    ssize_t ret, len;

    ret = lseek64(dev->fd, (off64_t) pos * (off64_t) SACD_LSN_SIZE, SEEK_SET);
    if (ret < 0)
    {
        return 0;
    }

    len = (size_t) blocks * SACD_LSN_SIZE;

    while (len > 0)
    {
        ret = read(dev->fd, buffer, (unsigned int) len);

        if (ret < 0)
        {
            /* One of the reads failed, too bad.  We won't even bother
             * returning the reads that went OK, and as in the POSIX spec
             * the file position is left unspecified after a failure. */
            return ret;
        }

        if (ret == 0)
        {
            /* Nothing more to read.  Return all of the whole blocks, if any.
             * Adjust the file position back to the previous block boundary. */
            ssize_t bytes     = (ssize_t) blocks * SACD_LSN_SIZE - len;
            off64_t over_read = -(bytes % SACD_LSN_SIZE);
            /*off_t pos =*/ lseek64(dev->fd, over_read, SEEK_CUR);
            /* should have pos % 2048 == 0 */
            return (int) (bytes / SACD_LSN_SIZE);
        }

        len -= ret;
    }

    return blocks;
}

/**
 * read data from the device via the sacd_read kernel module (64-bit capable).
 */
static int sacd_dev_input_read64(sacd_input_t dev, int pos, int blocks, void *buffer)
{
    int result = read_sacd(pos, blocks, buffer);
    if (result >= 0)
    {
        return blocks;
    }
    return 0;
}

/**
 * close the SACD device and clean up.
 */
static int sacd_dev_input_close(sacd_input_t dev)
{
    int ret;

    ret = close(dev->fd);

    if (sacd_input_read64 == sacd_dev_input_read64)
    {
        uninit_sacd();
    }

    free(dev);

    return ret;
}

static uint32_t sacd_dev_input_total_sectors(sacd_input_t dev)
{
    if (!dev)
        return 0;

    {
        struct stat64 file_stat;
        if (fstat64(dev->fd, &file_stat) < 0)
            return 0;

        if (file_stat.st_size == 0)
        {
            if (ioctl(dev->fd, BLKGETSIZE64, &file_stat.st_size) < 0)
                return 0;
        }

        return (uint32_t) (file_stat.st_size / SACD_LSN_SIZE);
    }
}

static int sacd_net_input_authenticate(sacd_input_t dev)
{
    return 0;
}

static int sacd_net_input_decrypt(sacd_input_t dev, uint8_t *buffer, int blocks)
{
    return 0;
}

/**
 * initialize and open a SACD device or file.
 */
static sacd_input_t sacd_net_input_open(const char *target)
{
    ServerRequest request;
    ServerResponse response;
    sacd_input_t dev = 0;
    const char *err = 0;
    t_timeout tm;
    pb_istream_t input;
    pb_ostream_t output;
    uint8_t zero = 0;

    /* Allocate the library structure */
    dev = (sacd_input_t) calloc(sizeof(*dev), 1);
    if (dev == NULL)
    {
        fprintf(stderr, "libsacdread: Could not allocate memory.\n");
        return NULL;
    }

    dev->input_buffer = (uint8_t *) malloc(MAX_PROCESSING_BLOCK_SIZE * SACD_LSN_SIZE + 1024);
    if (dev->input_buffer == NULL)
    {
        fprintf(stderr, "libsacdread: Could not allocate memory.\n");
        goto error;
    }

    socket_open();

    socket_create(&dev->fd, AF_INET, SOCK_STREAM, 0);
    socket_setblocking(&dev->fd);

    timeout_markstart(&tm);
    err = inet_tryconnect(&dev->fd, substr(target, 0, strchr(target, ':') - target), atoi(strchr(target, ':') + 1), &tm);
    if (err)
    {
        fprintf(stderr, "Failed to connect\n");
        goto error;
    }
    socket_setblocking(&dev->fd);

    input = pb_istream_from_socket(&dev->fd);
    output = pb_ostream_from_socket(&dev->fd);

    request.type = ServerRequest_Type_DISC_OPEN;

    if (!pb_encode(&output, ServerRequest_fields, &request))
    {
        fprintf(stderr, "Failed to encode request\n");
        goto error;
    }

    /* We signal the end of request with a 0 tag. */
    pb_write(&output, &zero, 1);

    if (!pb_decode(&input, ServerResponse_fields, &response))
    {
        fprintf(stderr, "Failed to decode response\n");
        goto error;
    }

    if (response.result == 0 && response.type == ServerResponse_Type_DISC_OPENED)
        goto open_ok;
    else
    {
        fprintf(stderr, "Response result non-zero or disc opened\n");
        goto error;
    }

open_ok:

    return dev;

error:

    sacd_input_close(dev);

    return 0;
}

/**
 * close the SACD device and clean up.
 */
static int sacd_net_input_close(sacd_input_t dev)
{
    if (!dev)
    {
        return 0;
    }
    else
    {
        ServerRequest request;
        ServerResponse response;
        pb_istream_t input = pb_istream_from_socket(&dev->fd);
        pb_ostream_t output = pb_ostream_from_socket(&dev->fd);
        uint8_t zero = 0;

        request.type = ServerRequest_Type_DISC_CLOSE;
        if (!pb_encode(&output, ServerRequest_fields, &request))
        {
            goto error;
        }

        pb_write(&output, &zero, 1);

        if (!pb_decode(&input, ServerResponse_fields, &response))
        {
            goto error;
        }

        if (response.result == 0 || response.type != ServerResponse_Type_DISC_CLOSED)
        {
            goto error;
        }
    }

error:

    if (dev != NULL)
    {
        socket_destroy(&dev->fd);
        socket_close();
        if (dev->input_buffer)
        {
            free(dev->input_buffer);
            dev->input_buffer = NULL;
        }
        free(dev);
        dev = NULL;
    }

    return 0;
}

static uint32_t sacd_net_input_total_sectors(sacd_input_t dev)
{
    if (!dev)
    {
        return 0;
    }
    else
    {
        ServerRequest request;
        ServerResponse response;
        pb_istream_t input = pb_istream_from_socket(&dev->fd);
        pb_ostream_t output = pb_ostream_from_socket(&dev->fd);
        uint8_t zero = 0;

        request.type = ServerRequest_Type_DISC_SIZE;

        if (!pb_encode(&output, ServerRequest_fields, &request))
        {
            return 0;
        }

        /* We signal the end of request with a 0 tag. */
        pb_write(&output, &zero, 1);

        if (!pb_decode(&input, ServerResponse_fields, &response))
        {
            return 0;
        }

        if (response.type != ServerResponse_Type_DISC_SIZE)
        {
            return 0;
        }

        return (uint32_t) response.result;
    }
}

static ssize_t sacd_net_input_read(sacd_input_t dev, int pos, int blocks, void *buffer)
{
    if (!dev)
    {
        return 0;
    }
    else
    {
        uint8_t output_buf[16];
        ServerRequest request;
        ServerResponse response;
        pb_ostream_t output = pb_ostream_from_buffer(output_buf, sizeof(output_buf));
        pb_istream_t input = pb_istream_from_socket(&dev->fd);
        uint8_t zero = 0;

        request.type = ServerRequest_Type_DISC_READ;
        request.sector_offset = pos;
        request.sector_count = blocks;

        if (!pb_encode(&output, ServerRequest_fields, &request))
        {
            return 0;
        }

        /* We signal the end of request with a 0 tag. */
        pb_write(&output, &zero, 1);

        // write the output buffer to the opened socket
        {
            bool ret;
            size_t written;
            ret = (socket_send(&dev->fd, (char *) output_buf, output.bytes_written, &written, 0, 0) == IO_DONE && written == output.bytes_written);

            if (!ret)
                return 0;
        }

        response.data.bytes = buffer;
        if (!pb_decode(&input, ServerResponse_fields, &response))
        {
            return 0;
        }

        if (response.type != ServerResponse_Type_DISC_READ)
        {
            return 0;
        }

        if (response.has_data)
        {
            return response.result;
        }
    }

    return 0;
}

/**
 * Setup read functions with either network or file access
 */
int sacd_input_setup(const char* path)
{
    int net_conn = 0;
    {
        // TODO: replace this F*(&^*($#^(&*#^$GLY hack to detect IP
        int i = 0;
        const char *c = path;
        while ((c = strchr(c + 1, '.')))
        {
            if (++i == 3 && strchr(c + 1, ':'))
            {
                net_conn = 1;
                break;
            }
        }
    }

    if (net_conn)
    {
        sacd_input_open = sacd_net_input_open;
        sacd_input_close = sacd_net_input_close;
        sacd_input_read = sacd_net_input_read;
        sacd_input_read64 = sacd_net_input_read;
        sacd_input_error = sacd_dev_input_error;
        sacd_input_authenticate  = sacd_net_input_authenticate;
        sacd_input_decrypt = sacd_net_input_decrypt;
        sacd_input_total_sectors = sacd_net_input_total_sectors;

        return 1;
    }

    if (strcmp(path, "/dev/sr0") == 0)
    {
        sacd_input_open = sacd_dev_input_open;
        sacd_input_close = sacd_dev_input_close;
        sacd_input_read = sacd_dev_input_read;
        sacd_input_read64 = sacd_dev_input_read64;
        sacd_input_error = sacd_dev_input_error;
        sacd_input_authenticate  = sacd_dev_input_authenticate;
        sacd_input_decrypt = sacd_dev_input_decrypt;
        sacd_input_total_sectors = sacd_dev_input_total_sectors;

        return 2;
    }

    sacd_input_open = sacd_dev_input_open;
    sacd_input_close = sacd_dev_input_close;
    sacd_input_read = sacd_dev_input_read;
    sacd_input_read64 = sacd_dev_input_read;
    sacd_input_error = sacd_dev_input_error;
    sacd_input_authenticate  = sacd_net_input_authenticate;
    sacd_input_decrypt = sacd_net_input_decrypt;
    sacd_input_total_sectors = sacd_dev_input_total_sectors;

    return 0;
}
