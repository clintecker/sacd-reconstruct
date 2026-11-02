/* Small GNU C 4.4.1 -O0 probes. Each external declaration stands in for a
 * real callee or object so the code can be compiled without target headers.
 * These are witnesses to code generation, not the recovered application. */
typedef unsigned long pthread_t;
struct device { int fd; int other; };
struct stream;
extern struct stream *stderr;
extern int open64(const char *, int, ...);
extern int close(int);
extern void *calloc(unsigned int, unsigned int);
extern void free(void *);
extern int fprintf(struct stream *, const char *, ...);
extern int init_sacd(void);
extern void *selection;
extern void expected(void);
extern void *client_thread(void *);
extern int pthread_create(pthread_t *, const void *, void *(*)(void *), void *);

/* There are two incoming edges to fail. Only the open-failure edge gets the
 * separate NOP in the tested compiler. The close call branches around it. */
struct device *open_probe(char *name)
{
    struct device *dev = calloc(sizeof(*dev), 1);
    if (!dev) {
        fprintf(stderr, "Could not open device: need more memory\n");
        return 0;
    }
    dev->fd = open64(name, 0);
    if (dev->fd < 0)
        goto fail;
    if (selection == (void *)expected && init_sacd() < 0) {
        close(dev->fd);
        goto fail;
    }
    return dev;
fail:
    free(dev);
    return 0;
}

/* A fourth argument requiring its own stack address changes temporary use.
 * Solely compilation probes: their addresses are not safe to hand to a live
 * thread after these functions return. */
int fd_address_probe(void)
{
    pthread_t id;
    int conn_s;
    return pthread_create(&id, 0, client_thread, &conn_s);
}

int null_argument_probe(void)
{
    pthread_t id;
    return pthread_create(&id, 0, client_thread, 0);
}
