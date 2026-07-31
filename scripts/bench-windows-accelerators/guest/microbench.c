#define _GNU_SOURCE

#include <errno.h>
#include <inttypes.h>
#include <pthread.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

static volatile uint64_t memory_sink;

static uint64_t now_ns(void)
{
    struct timespec value;

    if (clock_gettime(CLOCK_MONOTONIC, &value) != 0) {
        perror("clock_gettime");
        exit(EXIT_FAILURE);
    }
    return (uint64_t)value.tv_sec * UINT64_C(1000000000) + value.tv_nsec;
}

static uint64_t parse_u64(const char *value, const char *name)
{
    char *end = NULL;
    unsigned long long parsed;

    errno = 0;
    parsed = strtoull(value, &end, 10);
    if (errno != 0 || end == value || *end != '\0') {
        fprintf(stderr, "invalid %s: %s\n", name, value);
        exit(EXIT_FAILURE);
    }
    return parsed;
}

static const char *run_id(void)
{
    const char *value = getenv("BENCH_RUN_ID");

    return value != NULL && value[0] != '\0' ? value : "unassigned";
}

static bool is_prime(uint64_t value)
{
    uint64_t divisor;

    if (value < 2) {
        return false;
    }
    if (value == 2) {
        return true;
    }
    if ((value & 1) == 0) {
        return false;
    }
    for (divisor = 3; divisor <= value / divisor; divisor += 2) {
        if (value % divisor == 0) {
            return false;
        }
    }
    return true;
}

static uint64_t count_primes(uint64_t begin, uint64_t end)
{
    uint64_t count = 0;
    uint64_t value;

    for (value = begin; value < end; value++) {
        count += is_prime(value);
    }
    return count;
}

typedef struct PrimeWorker {
    uint64_t begin;
    uint64_t end;
    uint64_t count;
} PrimeWorker;

static void *prime_worker(void *opaque)
{
    PrimeWorker *worker = opaque;

    worker->count = count_primes(worker->begin, worker->end);
    return NULL;
}

static unsigned online_cpus(void)
{
    long count = sysconf(_SC_NPROCESSORS_ONLN);

    if (count < 1 || count > 256) {
        fprintf(stderr, "unsupported online CPU count: %ld\n", count);
        exit(EXIT_FAILURE);
    }
    return (unsigned)count;
}

static int run_prime_v1(void)
{
    const uint64_t limit = UINT64_C(3000000);
    const uint64_t expected = UINT64_C(216816);
    uint64_t started = now_ns();
    uint64_t count = count_primes(2, limit);
    uint64_t ended = now_ns();
    double seconds = (ended - started) / 1000000000.0;

    if (count != expected) {
        fprintf(stderr, "prime-v1 count mismatch: got %" PRIu64 ", expected %" PRIu64 "\n",
                count, expected);
        return EXIT_FAILURE;
    }

    printf("BENCH_JSON {\"schema\":1,\"run_id\":\"%s\",\"workload\":\"prime-v1\","
           "\"metric\":\"elapsed_seconds\",\"value\":%.9f,\"unit\":\"seconds\","
           "\"direction\":\"lower\",\"prime_limit\":%" PRIu64 ",\"prime_count\":%" PRIu64
           ",\"threads\":1,\"status\":\"success\"}\n",
           run_id(), seconds, limit, count);
    fflush(stdout);
    return EXIT_SUCCESS;
}

static int run_prime_smp(uint64_t limit, bool verify)
{
    const uint64_t known_limit = UINT64_C(10000000);
    const uint64_t known_count = UINT64_C(664579);
    unsigned threads_count = online_cpus();
    pthread_t *threads = calloc(threads_count, sizeof(*threads));
    PrimeWorker *workers = calloc(threads_count, sizeof(*workers));
    uint64_t span;
    uint64_t started;
    uint64_t ended;
    uint64_t total = 0;
    unsigned index;

    if (threads == NULL || workers == NULL || limit < 3) {
        fprintf(stderr, "unable to allocate prime workers\n");
        free(threads);
        free(workers);
        return EXIT_FAILURE;
    }

    span = limit - 2;
    started = now_ns();
    for (index = 0; index < threads_count; index++) {
        workers[index].begin = 2 + span * index / threads_count;
        workers[index].end = 2 + span * (index + 1) / threads_count;
        if (pthread_create(&threads[index], NULL, prime_worker, &workers[index]) != 0) {
            fprintf(stderr, "pthread_create failed for prime worker %u\n", index);
            return EXIT_FAILURE;
        }
    }
    for (index = 0; index < threads_count; index++) {
        if (pthread_join(threads[index], NULL) != 0) {
            fprintf(stderr, "pthread_join failed for prime worker %u\n", index);
            return EXIT_FAILURE;
        }
        total += workers[index].count;
    }
    ended = now_ns();

    if (limit == known_limit && total != known_count) {
        fprintf(stderr, "prime-smp count mismatch: got %" PRIu64 ", expected %" PRIu64 "\n",
                total, known_count);
        return EXIT_FAILURE;
    }
    if (verify && total != count_primes(2, limit)) {
        fprintf(stderr, "prime-smp single-thread verification failed\n");
        return EXIT_FAILURE;
    }

    printf("BENCH_JSON {\"schema\":1,\"run_id\":\"%s\",\"workload\":\"prime-smp\","
           "\"metric\":\"elapsed_seconds\",\"value\":%.9f,\"unit\":\"seconds\","
           "\"direction\":\"lower\",\"prime_limit\":%" PRIu64 ",\"prime_count\":%" PRIu64
           ",\"threads\":%u,\"verified\":%s,\"status\":\"success\"}\n",
           run_id(), (ended - started) / 1000000000.0, limit, total, threads_count,
           verify ? "true" : "false");
    fflush(stdout);
    free(threads);
    free(workers);
    return EXIT_SUCCESS;
}

typedef enum MemoryMode {
    MEMORY_SEQ_READ,
    MEMORY_SEQ_WRITE,
    MEMORY_RANDOM_READ,
} MemoryMode;

typedef struct MemoryShared {
    pthread_barrier_t ready;
    pthread_barrier_t start;
    uint64_t deadline_ns;
} MemoryShared;

typedef struct MemoryWorker {
    MemoryShared *shared;
    uint64_t *words;
    size_t word_count;
    MemoryMode mode;
    unsigned index;
    uint64_t bytes;
    uint64_t checksum;
} MemoryWorker;

static uint64_t xorshift64(uint64_t *state)
{
    uint64_t value = *state;

    value ^= value << 13;
    value ^= value >> 7;
    value ^= value << 17;
    *state = value;
    return value;
}

static void *memory_worker(void *opaque)
{
    MemoryWorker *worker = opaque;
    uint64_t bytes = 0;
    uint64_t checksum = 0;
    uint64_t random_state = UINT64_C(0x9e3779b97f4a7c15) ^ (worker->index + 1);

    pthread_barrier_wait(&worker->shared->ready);
    pthread_barrier_wait(&worker->shared->start);

    while (now_ns() < worker->shared->deadline_ns) {
        size_t index;

        switch (worker->mode) {
        case MEMORY_SEQ_READ:
            for (index = 0; index < worker->word_count; index++) {
                checksum += worker->words[index];
            }
            bytes += worker->word_count * sizeof(*worker->words);
            break;
        case MEMORY_SEQ_WRITE:
            for (index = 0; index < worker->word_count; index++) {
                worker->words[index] = random_state + index + bytes;
            }
            checksum += worker->words[worker->word_count - 1];
            bytes += worker->word_count * sizeof(*worker->words);
            break;
        case MEMORY_RANDOM_READ:
            for (index = 0; index < worker->word_count; index++) {
                size_t random_index = xorshift64(&random_state) % worker->word_count;
                checksum += worker->words[random_index];
            }
            bytes += worker->word_count * sizeof(*worker->words);
            break;
        }
    }

    worker->bytes = bytes;
    worker->checksum = checksum;
    return NULL;
}

static int run_memory(const char *workload, MemoryMode mode, uint64_t mib,
                      uint64_t duration_seconds)
{
    unsigned threads_count = online_cpus();
    uint64_t total_bytes = mib * UINT64_C(1024) * UINT64_C(1024);
    size_t total_words = total_bytes / sizeof(uint64_t);
    pthread_t *threads = NULL;
    MemoryWorker *workers = NULL;
    MemoryShared shared;
    uint64_t *buffer = NULL;
    uint64_t started;
    uint64_t ended;
    uint64_t bytes = 0;
    uint64_t checksum = 0;
    unsigned index;
    int result = EXIT_FAILURE;

    if (mib == 0 || duration_seconds == 0 || total_words < threads_count) {
        fprintf(stderr, "invalid memory benchmark size or duration\n");
        return EXIT_FAILURE;
    }
    if (posix_memalign((void **)&buffer, 64, total_words * sizeof(*buffer)) != 0) {
        fprintf(stderr, "unable to allocate %" PRIu64 " MiB memory buffer\n", mib);
        return EXIT_FAILURE;
    }
    threads = calloc(threads_count, sizeof(*threads));
    workers = calloc(threads_count, sizeof(*workers));
    if (threads == NULL || workers == NULL) {
        fprintf(stderr, "unable to allocate memory workers\n");
        goto cleanup;
    }

    for (index = 0; index < total_words; index++) {
        buffer[index] = UINT64_C(0x6a09e667f3bcc909) ^ index;
    }
    if (pthread_barrier_init(&shared.ready, NULL, threads_count + 1) != 0 ||
        pthread_barrier_init(&shared.start, NULL, threads_count + 1) != 0) {
        fprintf(stderr, "unable to initialize memory barriers\n");
        goto cleanup;
    }

    for (index = 0; index < threads_count; index++) {
        size_t begin = total_words * index / threads_count;
        size_t end = total_words * (index + 1) / threads_count;

        workers[index].shared = &shared;
        workers[index].words = buffer + begin;
        workers[index].word_count = end - begin;
        workers[index].mode = mode;
        workers[index].index = index;
        if (pthread_create(&threads[index], NULL, memory_worker, &workers[index]) != 0) {
            fprintf(stderr, "pthread_create failed for memory worker %u\n", index);
            exit(EXIT_FAILURE);
        }
    }

    pthread_barrier_wait(&shared.ready);
    started = now_ns();
    shared.deadline_ns = started + duration_seconds * UINT64_C(1000000000);
    pthread_barrier_wait(&shared.start);

    for (index = 0; index < threads_count; index++) {
        if (pthread_join(threads[index], NULL) != 0) {
            fprintf(stderr, "pthread_join failed for memory worker %u\n", index);
            goto cleanup;
        }
        bytes += workers[index].bytes;
        checksum ^= workers[index].checksum;
    }
    ended = now_ns();
    memory_sink = checksum;

    printf("BENCH_JSON {\"schema\":1,\"run_id\":\"%s\",\"workload\":\"%s\","
           "\"metric\":\"bytes_per_second\",\"value\":%.3f,\"unit\":\"bytes/s\","
           "\"direction\":\"higher\",\"working_set_mib\":%" PRIu64
           ",\"duration_seconds\":%.9f,\"bytes\":%" PRIu64 ",\"threads\":%u,"
           "\"checksum\":%" PRIu64 ",\"status\":\"success\"}\n",
           run_id(), workload, bytes / ((ended - started) / 1000000000.0), mib,
           (ended - started) / 1000000000.0, bytes, threads_count, checksum);
    fflush(stdout);
    result = EXIT_SUCCESS;
    pthread_barrier_destroy(&shared.start);
    pthread_barrier_destroy(&shared.ready);

cleanup:
    free(workers);
    free(threads);
    free(buffer);
    return result;
}

static void usage(const char *program)
{
    fprintf(stderr,
            "usage: %s prime-v1\n"
            "       %s prime-smp [limit] [verify]\n"
            "       %s memory-seq-read|memory-seq-write|memory-random [MiB] [seconds]\n",
            program, program, program);
}

int main(int argc, char **argv)
{
    if (argc < 2) {
        usage(argv[0]);
        return EXIT_FAILURE;
    }
    if (strcmp(argv[1], "prime-v1") == 0) {
        return run_prime_v1();
    }
    if (strcmp(argv[1], "prime-smp") == 0) {
        uint64_t limit = argc >= 3 ? parse_u64(argv[2], "prime limit") : UINT64_C(10000000);
        bool verify = argc >= 4 && strcmp(argv[3], "verify") == 0;

        return run_prime_smp(limit, verify);
    }
    if (strcmp(argv[1], "memory-seq-read") == 0 ||
        strcmp(argv[1], "memory-seq-write") == 0 ||
        strcmp(argv[1], "memory-random") == 0) {
        uint64_t mib = argc >= 3 ? parse_u64(argv[2], "working set MiB") : UINT64_C(512);
        uint64_t seconds = argc >= 4 ? parse_u64(argv[3], "duration seconds") : UINT64_C(15);
        MemoryMode mode = MEMORY_RANDOM_READ;

        if (strcmp(argv[1], "memory-seq-read") == 0) {
            mode = MEMORY_SEQ_READ;
        } else if (strcmp(argv[1], "memory-seq-write") == 0) {
            mode = MEMORY_SEQ_WRITE;
        }
        return run_memory(argv[1], mode, mib, seconds);
    }

    usage(argv[0]);
    return EXIT_FAILURE;
}
