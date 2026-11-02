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

/* Reconstructed community port ("sacd_extract_160") of sacd-ripper v0.3.7
 * for Sony Mediatek Blu-ray players. Deltas vs. the v0.3.7 trunk are
 * documented in ../../DELTA.md.
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <signal.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <wchar.h>
#include <locale.h>
#include <time.h>
#ifndef __APPLE__
#include <malloc.h>
#endif
#ifdef _WIN32
#include <io.h>
#endif

#include <pthread.h>

#include <charset.h>
#include <logging.h>
#include <yarn.h>
#include <socket.h>

#include <pb.h>
#include <pb_encode.h>
#include <pb_decode.h>
#include <sacd_pb_stream.h>
#include <sacd_ripper.pb.h>

#include "getopt.h"

#include <sacd_reader.h>
#include <sacd_read.h>
#include <scarletbook.h>
#include <scarletbook_read.h>
#include <scarletbook_output.h>
#include <scarletbook_print.h>
#include <scarletbook_helpers.h>
#include <scarletbook_id3.h>
#include <cuesheet.h>
#include <endianess.h>
#include <fileutils.h>
#include <utils.h>

#include "install.h"

static struct opts_s
{
    int            two_channel;
    int            multi_channel;
    int            output_dsf;
    int            output_dsdiff_em;
    int            output_dsdiff;
    int            output_iso;
    int            convert_dst;
    int            export_cue_sheet;
    int            print;
    char          *input_device; /* Access method driver should use for control */
    char           output_file[512];
    int            select_tracks;
    char           selected_tracks[256]; /* scarletbook is limited to 256 tracks */
    int            server_mode;
} opts;

scarletbook_handle_t *handle;
scarletbook_output_t *output;

static int client_connected = 0;
static int exit_requested = 0;

int is_client_connected(void)
{
    return client_connected;
}

int user_requested_exit(void)
{
    return exit_requested;
}

void requested_for_exit(int status)
{
    exit_requested = status;
}

static void client_thread(void *userdata)
{
    p_socket client = (p_socket) userdata;
    ServerRequest request;
    ServerResponse response;
    uint8_t zero = 0;
    uint8_t *output_buf = (uint8_t *) malloc(MAX_PROCESSING_BLOCK_SIZE * SACD_LSN_SIZE + 1024);
    pb_istream_t input = pb_istream_from_socket(client);
    pb_ostream_t output;
    sacd_reader_t   *sacd_reader = 0;
    scarletbook_handle_t *handle = 0;
    int non_encrypted_disc = 0;
    int checked_for_non_encrypted_disc = 0;
    uint32_t encrypted_start_1 = 0;
    uint32_t encrypted_start_2 = 0;
    uint32_t encrypted_end_1 = 0;
    uint32_t encrypted_end_2 = 0;
    uint32_t block_size = 0;
    uint32_t end_lsn = 0;

    client_connected = 1;

    response.data.bytes = (uint8_t *) malloc(MAX_PROCESSING_BLOCK_SIZE * SACD_RAW_SECTOR_SIZE);

    for (;;)
    {
        if (!pb_decode(&input, ServerRequest_fields, &request))
        {
            break;
        }

        response.has_data = false;
        response.data.size = 0;
        response.result = -1;

        switch(request.type)
        {
        case ServerRequest_Type_DISC_READ:
            {
                response.type = ServerResponse_Type_DISC_READ;
                if (handle && sacd_reader)
                {
                    int encrypted = 0;
                    end_lsn = request.sector_offset + request.sector_count;

                    // check what block ranges are encrypted..
                    if (request.sector_offset < encrypted_start_1)
                    {
                        block_size = min(encrypted_start_1 - request.sector_offset, MAX_PROCESSING_BLOCK_SIZE);
                        encrypted = 0;
                    }
                    else if (request.sector_offset >= encrypted_start_1 && request.sector_offset <= encrypted_end_1)
                    {
                        block_size = min(encrypted_end_1 + 1 - request.sector_offset, MAX_PROCESSING_BLOCK_SIZE);
                        encrypted = 1;
                    }
                    else if (request.sector_offset > encrypted_end_1 && request.sector_offset < encrypted_start_2)
                    {
                        block_size = min(encrypted_start_2 - request.sector_offset, MAX_PROCESSING_BLOCK_SIZE);
                        encrypted = 0;
                    }
                    else if (request.sector_offset >= encrypted_start_2 && request.sector_offset <= encrypted_end_2)
                    {
                        block_size = min(encrypted_end_2 + 1 - request.sector_offset, MAX_PROCESSING_BLOCK_SIZE);
                        encrypted = 1;
                    }
                    block_size = min(end_lsn - request.sector_offset, block_size);

                    response.result = sacd_read_block_raw64(sacd_reader, request.sector_offset, block_size, response.data.bytes);
                    response.has_data = response.result > 0;
                    response.data.size = response.result * SACD_LSN_SIZE;

                    sacd_decrypt(sacd_reader, response.data.bytes, block_size);
                }
            }
            break;
        case ServerRequest_Type_DISC_OPEN:
            response.type = ServerResponse_Type_DISC_OPENED;
            sacd_reader = sacd_open("/dev/sr0");
            if (sacd_reader)
            {
                handle = scarletbook_open(sacd_reader, 0);
                checked_for_non_encrypted_disc = 0;
                non_encrypted_disc = 0;

                if (handle)
                {
                    // set the encryption range
                    if (handle->area[0].area_toc != 0)
                    {
                        encrypted_start_1 = handle->area[0].area_toc->track_start;
                        encrypted_end_1 = handle->area[0].area_toc->track_end;
                    }
                    if (handle->area[1].area_toc != 0)
                    {
                        encrypted_start_2 = handle->area[1].area_toc->track_start;
                        encrypted_end_2 = handle->area[1].area_toc->track_end;
                    }

                    response.result = sacd_authenticate(sacd_reader);
                }
            }
            break;
        case ServerRequest_Type_DISC_CLOSE:
            {
                response.type = ServerResponse_Type_DISC_CLOSED;
                if (handle)
                {
                    scarletbook_close(handle);
                    handle = 0;
                }
                if (sacd_reader)
                {
                    sacd_close(sacd_reader);
                    sacd_reader = 0;
                }
                response.result = 0;
            }
            break;
        case ServerRequest_Type_DISC_SIZE:
            response.type = ServerResponse_Type_DISC_SIZE;
            if (sacd_reader)
            {
                response.result = sacd_get_total_sectors(sacd_reader);
            }
            break;
        }

        // reset output stream
        output = pb_ostream_from_buffer(output_buf, MAX_PROCESSING_BLOCK_SIZE * SACD_LSN_SIZE + 1024);

        if (!pb_encode(&output, ServerResponse_fields, &response))
        {
            break;
        }

        /* We signal the end of a request with a 0 tag. */
        pb_write(&output, &zero, 1);

        // write the output buffer to the opened socket
        {
            bool ret;
            size_t written;
            ret = (socket_send(client, (char *) output_buf, output.bytes_written, &written, 0, 0) == IO_DONE && written == output.bytes_written);

            if (!ret)
                break;
        }

        if (request.type == ServerRequest_Type_DISC_CLOSE)
        {
            break;
        }
    }

    if (handle)
        scarletbook_close(handle);

    if (sacd_reader)
        sacd_close(sacd_reader);

    free(response.data.bytes);
    free(output_buf);

    close(*client);
    client_connected = 0;

    pthread_exit(0);
}

void listener_thread(void *unused)
{
    pthread_t id;
    struct sockaddr_in sa;
    memset(&sa, 0, sizeof(sa));

    sa.sin_family = AF_INET;
    sa.sin_port = htons(2002);
    sa.sin_addr.s_addr = htonl(INADDR_ANY);

    int list_s = socket(PF_INET, SOCK_STREAM, IPPROTO_TCP);

    // only 1 socket connection is allowed at once
    if(bind(list_s, (struct sockaddr *)&sa, sizeof(sa)) == -1 || listen(list_s, 1) == -1)
    {
        pthread_exit(0);
    }

    int conn_s;

    while (!user_requested_exit())
    {
        if((conn_s = accept(list_s, NULL, NULL)) > 0)
        {
            pthread_create(&id, 0, client_thread, (void *)&conn_s);
        }
    }

    close(list_s);

    pthread_exit(0);
}

/* Parse all options. */
static int parse_options(int argc, char *argv[])
{
    int opt; /* used for argument parsing */
    char *program_name = NULL;

    static const char help_text[] =
        "Usage: %s [options] [outfile]\n"
        "  -2, --2ch-tracks                : Export two channel tracks (default)\n"
        "  -m, --mch-tracks                : Export multi-channel tracks\n"
        "  -e, --output-dsdiff-em          : output as Philips DSDIFF (Edit Master) file\n"
        "  -p, --output-dsdiff             : output as Philips DSDIFF file\n"
        "  -s, --output-dsf                : output as Sony DSF file\n"
        "  -t, --select-track              : only output selected track(s) (ex. -t 1,5,13)\n"
        "  -I, --output-iso                : output as RAW ISO\n"
        "  -c, --convert-dst               : convert DST to DSD\n"
        "  -C, --export-cue                : Export a CUE Sheet\n"
        "  -i, --input[=FILE]              : set source and determine if \"iso\" image, \n"
        "                                    device or server (ex. -i 192.168.1.10:2002)\n"
        "  -P, --print                     : display disc and track information\n"
        "  -S, --server-mode               : start in a server mode\n"
        "\n"
        "Help options:\n"
        "  -?, --help                      : Show this help message\n"
        "  --usage                         : Display brief usage message\n";

    static const char usage_text[] =
        "Usage: %s [-2|--2ch-tracks] [-m|--mch-tracks] [-p|--output-dsdiff]\n"
        "        [-e|--output-dsdiff-em] [-s|--output-dsf] [-I|--output-iso]\n"
        "        [-c|--convert-dst] [-C|--export-cue] [-i|--input FILE] [-P|--print]\n"
        "        [-S|--server-mode]\n"
        "        [-?|--help] [--usage]\n";

    static const char options_string[] = "2mepsSIcCi:t:P?";
    static const struct option options_table[] = {
        {"2ch-tracks", no_argument, NULL, '2' },
        {"mch-tracks", no_argument, NULL, 'm' },
        {"output-dsdiff-em", no_argument, NULL, 'e'},
        {"output-dsdiff", no_argument, NULL, 'p'},
        {"output-dsf", no_argument, NULL, 's'},
        {"output-iso", no_argument, NULL, 'I'},
        {"convert-dst", no_argument, NULL, 'c'},
        {"export-cue", no_argument, NULL, 'C'},
        {"input", required_argument, NULL, 'i' },
        {"print", no_argument, NULL, 'P' },
        {"server-mode", no_argument, NULL, 'S' },

        {"help", no_argument, NULL, '?' },
        {"usage", no_argument, NULL, 'u' },
        { NULL, 0, NULL, 0 }
    };

    program_name = strrchr(argv[0],'/');
    program_name = program_name ? strdup(program_name+1) : strdup(argv[0]);

    while ((opt = getopt_long(argc, argv, options_string, options_table, NULL)) >= 0) {
        switch (opt) {
        case '2':
            opts.two_channel = 1;
            break;
        case 'm':
            opts.multi_channel = 1;
            break;
        case 'e':
            opts.output_dsdiff_em = 1;
            opts.output_dsdiff = 0;
            opts.output_dsf = 0;
            opts.output_iso = 0;
            opts.export_cue_sheet = 1;
            break;
        case 'p':
            opts.output_dsdiff_em = 0;
            opts.output_dsdiff = 1;
            opts.output_dsf = 0;
            opts.output_iso = 0;
            break;
        case 's':
            opts.output_dsdiff_em = 0;
            opts.output_dsdiff = 0;
            opts.output_dsf = 1;
            opts.output_iso = 0;
            break;
        case 't':
            {
                int track_nr, count = 0;
                char *track = strtok(optarg, " ,");
                while (track != 0)
                {
                    track_nr = atoi(track);
                    track = strtok(0, " ,");
                    if (!track_nr)
                        continue;
                    track_nr = (track_nr - 1) & 0xff;
                    opts.selected_tracks[track_nr] = 1;
                    count++;
                }
                opts.select_tracks = count != 0;
            }
            break;
        case 'I':
            opts.output_dsdiff_em = 0;
            opts.output_dsdiff = 0;
            opts.output_dsf = 0;
            opts.output_iso = 1;
            break;
        case 'c': opts.convert_dst = 1; break;
        case 'C': opts.export_cue_sheet = 1; break;
        case 'i': opts.input_device = strdup(optarg); break;
        case 'P': opts.print = 1; break;
        case 'S': opts.server_mode = 1; break;

        case '?':
            fprintf(stdout, help_text, program_name);
            free(program_name);
            return 0;
            break;

        case 'u':
            fprintf(stderr, usage_text, program_name);
            free(program_name);
            return 0;
            break;
        }
    }

    if (optind < argc) {
        const char *remaining_arg = argv[optind++];
        strcpy(opts.output_file, remaining_arg);
    }

    return 1;
}

static lock *g_fwprintf_lock = 0;

static int safe_fwprintf(FILE *stream, const wchar_t *format, ...)
{
    int retval;
    va_list arglist;

    possess(g_fwprintf_lock);

    va_start(arglist, format);
    retval = vfwprintf(stream, format, arglist);
    va_end(arglist);

    fflush(stream);

    release(g_fwprintf_lock);

    return retval;
}

static void handle_sigint(int sig_no)
{
    safe_fwprintf(stdout, L"\rUser interrupted..                                                      \n");
    if (output)
        scarletbook_output_interrupt(output);
    requested_for_exit(1);
}

static void handle_status_update_track_callback(char *filename, int current_track, int total_tracks)
{
#ifdef _WIN32
    wchar_t *wide_filename = (wchar_t *) charset_convert(filename, strlen(filename), "UTF-8", sizeof(wchar_t) == 2 ? "UCS-2-INTERNAL" : "UCS-4-INTERNAL");
#else
    wchar_t *wide_filename = (wchar_t *) charset_convert(filename, strlen(filename), "UTF-8", "WCHAR_T");
#endif
    safe_fwprintf(stdout, L"\rProcessing [%ls] (%d/%d)..\n", wide_filename, current_track, total_tracks);
    free(wide_filename);
}

static time_t started_processing;

static void handle_status_update_progress_callback(uint32_t stats_total_sectors, uint32_t stats_total_sectors_processed,
                                 uint32_t stats_current_file_total_sectors, uint32_t stats_current_file_sectors_processed)
{
    safe_fwprintf(stdout, L"\rCompleted: %d%% (%.1fMB), Total: %d%% (%.1fMB) at %.2fMB/sec", (stats_current_file_sectors_processed*100/stats_current_file_total_sectors),
                                             ((float)((double) stats_current_file_sectors_processed * SACD_LSN_SIZE / 1048576.00)),
                                             (stats_total_sectors_processed * 100 / stats_total_sectors),
                                             ((float)((double) stats_current_file_total_sectors * SACD_LSN_SIZE / 1048576.00)),
                                             (float)((double) stats_total_sectors_processed * SACD_LSN_SIZE / 1048576.00) / (float)(time(0) - started_processing)
                                             );
}

/* Initialize global variables. */
static void init(void)
{
    /* Default option values. */
    opts.two_channel        = 0;
    opts.multi_channel      = 0;
    opts.output_dsf         = 0;
    opts.output_iso         = 0;
    opts.output_dsdiff      = 0;
    opts.output_dsdiff_em   = 0;
    opts.convert_dst        = 0;
    opts.export_cue_sheet   = 0;
    opts.print              = 0;
    opts.input_device       = "/dev/sr0";

    struct sigaction sa;
    memset(&sa, 0, sizeof(sa));
    sa.sa_handler = &handle_sigint;
    sigaction(SIGINT, &sa, NULL);

    init_logging();
    g_fwprintf_lock = new_lock(0);
}

void main_loop(void)
{
    char *albumdir = 0, *musicfilename, *file_path = 0;
    int i, area_idx;
    sacd_reader_t *sacd_reader;

    // default to 2 channel
    if (opts.two_channel == 0 && opts.multi_channel == 0)
    {
        opts.two_channel = 1;
    }

    sacd_reader = sacd_open(opts.input_device);
    if (sacd_reader)
    {
        handle = scarletbook_open(sacd_reader, 0);
        if (handle)
        {
            int authenticate_result = sacd_authenticate(sacd_reader);
            if (authenticate_result)
            {
                LOG(lm_main, LOG_ERROR, ("authentication failed: %x", authenticate_result));
            }

            if (opts.print)
            {
                scarletbook_print(handle);
            }

            if (opts.output_dsf || opts.output_iso || opts.output_dsdiff || opts.output_dsdiff_em || opts.export_cue_sheet)
            {
                output = scarletbook_output_create(handle, handle_status_update_track_callback, handle_status_update_progress_callback, safe_fwprintf);

                // select the channel area
                area_idx = ((has_multi_channel(handle) && opts.multi_channel) || !has_two_channel(handle)) ? handle->mulch_area_idx : handle->twoch_area_idx;

                albumdir = (strlen(opts.output_file) > 0 ? strdup(opts.output_file) : get_album_dir(handle));

                if (opts.output_iso)
                {
                    uint32_t total_sectors = sacd_get_total_sectors(sacd_reader);
                    {
                        get_unique_filename(&albumdir, "iso");
                        file_path = make_filename(0, 0, albumdir, "iso");
                        scarletbook_output_enqueue_raw_sectors(output, 0, total_sectors, file_path, "iso");
                    }
                }
                else if (opts.output_dsdiff_em)
                {
                    get_unique_filename(&albumdir, "dff");
                    file_path = make_filename(0, 0, albumdir, "dff");

                    scarletbook_output_enqueue_track(output, area_idx, 0, file_path, "dsdiff_edit_master",
                        (opts.convert_dst ? 1 : handle->area[area_idx].area_toc->frame_format != FRAME_FORMAT_DST));
                }
                else if (opts.output_dsf || opts.output_dsdiff)
                {
                    // create the output folder
                    get_unique_dir(0, &albumdir);
                    recursive_mkdir(albumdir, 0774);

                    // fill the queue with items to rip
                    for (i = 0; i < handle->area[area_idx].area_toc->track_count; i++)
                    {
                        if (opts.select_tracks && opts.selected_tracks[i] == 0)
                            continue;

                        musicfilename = get_music_filename(handle, area_idx, i, opts.output_file);
                        if (opts.output_dsf)
                        {
                            file_path = make_filename(0, albumdir, musicfilename, "dsf");
                            scarletbook_output_enqueue_track(output, area_idx, i, file_path, "dsf",
                                1 /* always decode to DSD */);
                        }
                        else if (opts.output_dsdiff)
                        {
                            file_path = make_filename(0, albumdir, musicfilename, "dff");
                            scarletbook_output_enqueue_track(output, area_idx, i, file_path, "dsdiff",
                                (opts.convert_dst ? 1 : handle->area[area_idx].area_toc->frame_format != FRAME_FORMAT_DST));
                        }

                        free(musicfilename);
                        free(file_path);
                        file_path = 0;
                    }
                }

                if (opts.export_cue_sheet)
                {
                    char *cue_file_path = make_filename(0, 0, albumdir, "cue");
#ifdef _WIN32
                    wchar_t *wide_filename = (wchar_t *) charset_convert(cue_file_path, strlen(cue_file_path), "UTF-8", sizeof(wchar_t) == 2 ? "UCS-2-INTERNAL" : "UCS-4-INTERNAL");
#else
                    wchar_t *wide_filename = (wchar_t *) charset_convert(cue_file_path, strlen(cue_file_path), "UTF-8", "WCHAR_T");
#endif
                    fwprintf(stdout, L"Exporting CUE sheet [%ls]\n", wide_filename);
                    if (!file_path)
                        file_path = make_filename(0, 0, albumdir, "dff");
                    write_cue_sheet(handle, file_path, area_idx, cue_file_path);
                    free(cue_file_path);
                    free(wide_filename);
                }

                free(file_path);

                started_processing = time(0);
                scarletbook_output_start(output);
                scarletbook_output_destroy(output);

                fprintf(stdout, "\rWe are done..                                                          \n");
            }
            scarletbook_close(handle);

            free(albumdir);
        }
    }

    sacd_close(sacd_reader);
}

static int validate_stdin(void)
{
    int result = tcgetpgrp(0);
    if (result != -1)
    {
        if (getpgrp() == result)
            result = 0;
        else
            result = -1;
    }
    return result;
}

void server_loop(void)
{
    int has_disc;
    int is_sacd;
    int have_console = validate_stdin();
    if (have_console == 0)
    {
        set_log_file("/dev/null");
    }
    while (!user_requested_exit())
    {
        if (have_console != 0)
        {
            has_disc = (disc_sacd() == 0);
            if (has_disc)
                is_sacd = !(sacd_sacd() < 0);
            safe_fwprintf(stdout, L"\rSACD Daemon %ls active. Client %ls. %ls.              ",
                          L"0.37",
                          is_client_connected() ? L"c" : L"n",
                          !has_disc ? L"Tray is empty" : (is_sacd ? L"SACD disc inserted" : L"Disc inserted"));
        }
        sleep(1);
    }
}

int main(int argc, char* argv[])
{
#ifdef PTW32_STATIC_LIB
    pthread_win32_process_attach_np();
    pthread_win32_thread_attach_np();
#endif

    init();
    if (parse_options(argc, argv))
    {
        if (install_modules() >= 0)
        {
            setlocale(LC_ALL, "");
            if (fwide(stdout, 1) < 0)
            {
                fprintf(stderr, "ERROR: Output not set to wide.\n");
            }

            if (opts.server_mode)
            {
                pthread_t thread;
                int rc = pthread_create(&thread, NULL, listener_thread, NULL);
                if (rc == 0)
                    goto server_started;

                LOG(lm_main, LOG_ERROR, ("return code from listener thread creation is %d\n", rc));
                goto loops_done;

server_started:
                server_loop();
                goto loops_done;
            }
            else
            {
                main_loop();
            }

loops_done:
            ;

#ifndef _WIN32
            freopen(0, "w", stdout);
#endif
            if (fwide(stdout, -1) >= 0)
            {
                fprintf(stderr, "ERROR: Output not set to byte oriented.\n");
            }

            remove_modules();
        }
        else
        {
            LOG(lm_main, LOG_ERROR, ("Can not install modules"));
        }
    }

    free_lock(g_fwprintf_lock);
    destroy_logging();

#ifdef PTW32_STATIC_LIB
    pthread_win32_process_detach_np();
    pthread_win32_thread_detach_np();
#endif

    putchar('\n');
    return 0;
}
