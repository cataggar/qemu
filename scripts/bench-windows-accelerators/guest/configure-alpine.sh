#!/bin/sh

set -eu

test -f etc/alpine-release || {
    echo "configure-alpine.sh must run from the mounted Alpine image root" >&2
    exit 1
}

root_uuid=$(sed -n 's/^UUID=\([^[:space:]]*\).*/\1/p' etc/fstab | head -n 1)
test -n "$root_uuid" || {
    echo "unable to read root filesystem UUID" >&2
    exit 1
}

echo qemu-accelerator-bench > etc/hostname

mkdir -p usr/local/sbin etc/init.d etc/runlevels/default boot/EFI/BOOT tmp
chmod 1777 tmp

cat > usr/local/sbin/benchmark-job <<'EOF'
#!/bin/sh

set -eu

if test -c /dev/ttyS0; then
    exec >/dev/ttyS0 2>&1
fi

service_start_uptime=$(cut -d ' ' -f 1 /proc/uptime)
run_id=unassigned
workload=
requested_vcpus=
host_ip=
guest_ip=
prefix_length=24
disk_device=
operation=
access_mode=
block_size=
duration_seconds=
ramp_seconds=
iodepth=
numjobs=
parallel_streams=
cpu_max_prime=

emit_error()
{
    message="$1"
    printf 'BENCH_JSON {"schema":1,"run_id":"%s","workload":"%s","status":"error","message":"%s"}\n' \
        "$run_id" "${workload:-unknown}" "$message"
}

power_off()
{
    sync
    sleep 1
    poweroff -f
    while :; do sleep 3600; done
}

fail()
{
    emit_error "$1"
    power_off
}

validate_token()
{
    value="$1"
    case "$value" in
        ''|*[!A-Za-z0-9._:/-]*) return 1 ;;
    esac
    return 0
}

validate_integer()
{
    value="$1"
    case "$value" in
        ''|*[!0-9]*) return 1 ;;
    esac
    return 0
}

printf 'BENCH_READY run_id=%s\n' "$run_id"

modprobe sr_mod 2>/dev/null ||:
modprobe isofs 2>/dev/null ||:
modprobe hv_storvsc 2>/dev/null ||:
modprobe hv_netvsc 2>/dev/null ||:
modprobe virtio_blk 2>/dev/null ||:
modprobe virtio_net 2>/dev/null ||:
mdev -s

config_mount=/run/benchcfg
mkdir -p "$config_mount"
config_device=
attempt=0
while test "$attempt" -lt 60; do
    for device in /dev/sr* /dev/cdrom; do
        test -b "$device" || continue
        if mount -t iso9660 -o ro "$device" "$config_mount" 2>/dev/null; then
            if test -f "$config_mount/job.conf"; then
                config_device="$device"
                break
            fi
            umount "$config_mount"
        fi
    done
    test -n "$config_device" && break
    attempt=$((attempt + 1))
    sleep 1
done
test -n "$config_device" || fail "BENCHCFG media was not found"
test -f "$config_mount/job.conf" || fail "BENCHCFG media has no job.conf"

while IFS='=' read -r key value; do
    case "$key" in
        ''|'#'*) continue ;;
        schema)
            test "$value" = 1 || fail "unsupported job schema"
            ;;
        run_id) run_id="$value" ;;
        workload) workload="$value" ;;
        vcpus) requested_vcpus="$value" ;;
        host_ip) host_ip="$value" ;;
        guest_ip) guest_ip="$value" ;;
        prefix_length) prefix_length="$value" ;;
        disk_device) disk_device="$value" ;;
        operation) operation="$value" ;;
        access_mode) access_mode="$value" ;;
        block_size) block_size="$value" ;;
        duration_seconds) duration_seconds="$value" ;;
        ramp_seconds) ramp_seconds="$value" ;;
        iodepth) iodepth="$value" ;;
        numjobs) numjobs="$value" ;;
        parallel_streams) parallel_streams="$value" ;;
        cpu_max_prime) cpu_max_prime="$value" ;;
        *) fail "unsupported job key" ;;
    esac
done < "$config_mount/job.conf"

validate_token "$run_id" || fail "invalid run ID"
validate_token "$workload" || fail "invalid workload"
online_vcpus=$(nproc)
if test -n "$requested_vcpus"; then
    validate_integer "$requested_vcpus" || fail "invalid requested vCPU count"
    test "$requested_vcpus" -eq "$online_vcpus" ||
        fail "online vCPU count does not match the job"
fi

service_ready_uptime=$(cut -d ' ' -f 1 /proc/uptime)
service_ready_seconds=$(awk -v start="$service_start_uptime" -v ready="$service_ready_uptime" \
    'BEGIN { printf "%.6f", ready - start }')
printf 'BENCH_READY run_id=%s workload=%s\n' "$run_id" "$workload"
printf 'BENCH_JSON {"schema":1,"run_id":"%s","workload":"guest-metadata","metric":"online_vcpus","value":%s,"unit":"count","direction":"exact","status":"success"}\n' \
    "$run_id" "$online_vcpus"

network_interface=
for interface_path in /sys/class/net/*; do
    interface=${interface_path##*/}
    test "$interface" = lo && continue
    network_interface="$interface"
    break
done

configure_network()
{
    test -n "$network_interface" || fail "no guest network interface was detected"
    ip link set "$network_interface" up
    if test -n "$guest_ip"; then
        validate_token "$guest_ip" || fail "invalid guest IP"
        validate_integer "$prefix_length" || fail "invalid prefix length"
        ip addr flush dev "$network_interface"
        ip addr add "$guest_ip/$prefix_length" dev "$network_interface"
    else
        udhcpc -q -n -i "$network_interface" || fail "DHCP configuration failed"
    fi
}

emit_raw_json()
{
    file="$1"
    printf 'BENCH_RAW_JSON '
    tr -d '\r\n' < "$file"
    printf '\n'
}

case "$workload" in
    smoke)
        sysbench_version=$(sysbench --version | tr -d '\r\n')
        fio_version=$(fio --version | tr -d '\r\n')
        iperf_version=$(iperf3 --version | head -n 1 | tr -d '\r\n')
        test -n "$network_interface" || fail "no virtio or Hyper-V network interface was detected"
        printf 'BENCH_JSON {"schema":1,"run_id":"%s","workload":"smoke","metric":"ready","value":1,"unit":"boolean","direction":"exact","sysbench":"%s","fio":"%s","iperf3":"%s","network_interface":"%s","status":"success"}\n' \
            "$run_id" "$sysbench_version" "$fio_version" "$iperf_version" "$network_interface"
        ;;
    full-boot)
        printf 'BENCH_JSON {"schema":1,"run_id":"%s","workload":"full-boot","metric":"service_ready_seconds","value":%s,"unit":"seconds","direction":"lower","status":"success"}\n' \
            "$run_id" "$service_ready_seconds"
        ;;
    sysbench-cpu)
        validate_integer "${duration_seconds:-}" || fail "invalid sysbench duration"
        validate_integer "${cpu_max_prime:-}" || fail "invalid CPU prime limit"
        output=/tmp/sysbench.txt
        sysbench cpu --threads="$online_vcpus" --time="$duration_seconds" \
            --cpu-max-prime="$cpu_max_prime" run > "$output" ||
            fail "sysbench CPU failed"
        value=$(sed -n 's/^[[:space:]]*events per second:[[:space:]]*//p' "$output" | tail -n 1)
        test -n "$value" || fail "unable to parse sysbench CPU output"
        printf 'BENCH_JSON {"schema":1,"run_id":"%s","workload":"%s","metric":"events_per_second","value":%s,"unit":"events/s","direction":"higher","threads":%s,"status":"success"}\n' \
            "$run_id" "$workload" "$value" "$online_vcpus"
        ;;
    sysbench-memory-*)
        validate_integer "${duration_seconds:-}" || fail "invalid sysbench duration"
        validate_token "${operation:-}" || fail "invalid memory operation"
        validate_token "${access_mode:-}" || fail "invalid memory access mode"
        validate_token "${block_size:-}" || fail "invalid memory block size"
        output=/tmp/sysbench.txt
        sysbench memory --threads="$online_vcpus" --time="$duration_seconds" \
            --events=0 --memory-total-size=1T --memory-oper="$operation" \
            --memory-access-mode="$access_mode" --memory-block-size="$block_size" run > "$output" ||
            fail "sysbench memory failed"
        value=$(sed -n 's/.*(\([0-9.][0-9.]*\) MiB\/sec).*/\1/p' "$output" | tail -n 1)
        test -n "$value" || fail "unable to parse sysbench memory output"
        printf 'BENCH_JSON {"schema":1,"run_id":"%s","workload":"%s","metric":"mib_per_second","value":%s,"unit":"MiB/s","direction":"higher","threads":%s,"status":"success"}\n' \
            "$run_id" "$workload" "$value" "$online_vcpus"
        ;;
    fio-*)
        validate_token "${disk_device:-}" || fail "invalid fio disk device"
        validate_token "${operation:-}" || fail "invalid fio operation"
        validate_token "${block_size:-}" || fail "invalid fio block size"
        validate_integer "${duration_seconds:-}" || fail "invalid fio duration"
        validate_integer "${ramp_seconds:-}" || fail "invalid fio ramp duration"
        validate_integer "${iodepth:-}" || fail "invalid fio iodepth"
        validate_integer "${numjobs:-}" || fail "invalid fio numjobs"
        test -b "$disk_device" || fail "fio disk device was not found"
        output=/tmp/fio.json
        fio --name=bench --filename="$disk_device" --rw="$operation" --bs="$block_size" \
            --ioengine=libaio --iodepth="$iodepth" --numjobs="$numjobs" --direct=1 \
            --time_based=1 --ramp_time="$ramp_seconds" --runtime="$duration_seconds" \
            --group_reporting=1 --eta=never --output-format=json --output="$output" ||
            fail "fio failed"
        case "$operation" in
            read|randread) value=$(jq '[.jobs[].read.bw_bytes] | add' "$output") ;;
            write|randwrite) value=$(jq '[.jobs[].write.bw_bytes] | add' "$output") ;;
            *) fail "unsupported fio operation" ;;
        esac
        emit_raw_json "$output"
        printf 'BENCH_JSON {"schema":1,"run_id":"%s","workload":"%s","metric":"bytes_per_second","value":%s,"unit":"bytes/s","direction":"higher","status":"success"}\n' \
            "$run_id" "$workload" "$value"
        ;;
    iperf-guest-to-host-*)
        validate_token "${host_ip:-}" || fail "invalid iperf host IP"
        validate_integer "${duration_seconds:-}" || fail "invalid iperf duration"
        validate_integer "${parallel_streams:-}" || fail "invalid iperf stream count"
        configure_network
        iperf3 -c "$host_ip" -P "$parallel_streams" -t 1 --json > /tmp/iperf-warmup.json ||
            fail "iperf3 connectivity warmup failed"
        output=/tmp/iperf.json
        iperf3 -c "$host_ip" -P "$parallel_streams" -t "$duration_seconds" --json > "$output" ||
            fail "iperf3 client failed"
        value=$(jq '.end.sum_sent.bits_per_second' "$output")
        emit_raw_json "$output"
        printf 'BENCH_JSON {"schema":1,"run_id":"%s","workload":"%s","metric":"bits_per_second","value":%s,"unit":"bits/s","direction":"higher","status":"success"}\n' \
            "$run_id" "$workload" "$value"
        ;;
    iperf-host-to-guest-*)
        validate_token "${host_ip:-}" || fail "invalid iperf host IP"
        validate_integer "${parallel_streams:-}" || fail "invalid iperf stream count"
        configure_network
        printf 'BENCH_IPERF_WARMUP_SERVER_READY run_id=%s streams=%s\n' "$run_id" "$parallel_streams"
        iperf3 -s -1 > /tmp/iperf-warmup.txt || fail "iperf3 server warmup failed"
        output=/tmp/iperf.json
        printf 'BENCH_IPERF_SERVER_READY run_id=%s streams=%s\n' "$run_id" "$parallel_streams"
        iperf3 -s -1 --json > "$output" || fail "iperf3 server failed"
        value=$(jq '.end.sum_received.bits_per_second' "$output")
        emit_raw_json "$output"
        printf 'BENCH_JSON {"schema":1,"run_id":"%s","workload":"%s","metric":"bits_per_second","value":%s,"unit":"bits/s","direction":"higher","status":"success"}\n' \
            "$run_id" "$workload" "$value"
        ;;
    *)
        fail "unsupported workload"
        ;;
esac

power_off
EOF
chmod 0755 usr/local/sbin/benchmark-job

cat > etc/init.d/benchmark <<'EOF'
#!/sbin/openrc-run

description="Run the configured accelerator benchmark job"

depend()
{
    need localmount
    after modules
}

start()
{
    ebegin "Running accelerator benchmark job"
    /usr/local/sbin/benchmark-job
    eend $?
}
EOF
chmod 0755 etc/init.d/benchmark
ln -sf /etc/init.d/benchmark etc/runlevels/default/benchmark

# The benchmark service owns COM1; a login prompt would corrupt serial records.
sed -i '/^ttyS0:/s/^/#/' etc/inittab

cat > tmp/grub.cfg <<EOF
serial --unit=0 --speed=38400 --word=8 --parity=no --stop=1
terminal_input serial
terminal_output serial
set timeout=0
set default=0

menuentry "Alpine benchmark" {
    linux (memdisk)/boot/vmlinuz-virt root=UUID=$root_uuid rootfstype=ext4 modules=ext4,scsi,virtio,network,cdrom console=tty0 console=ttyS0,38400n8
    initrd (memdisk)/boot/initramfs-virt
}
EOF

TMPDIR=/tmp chroot . grub-mkstandalone \
    --format=x86_64-efi \
    --output=/boot/EFI/BOOT/BOOTX64.EFI \
    --locales= \
    --fonts= \
    "boot/grub/grub.cfg=/tmp/grub.cfg" \
    "boot/vmlinuz-virt=/boot/vmlinuz-virt" \
    "boot/initramfs-virt=/boot/initramfs-virt"
test -s boot/EFI/BOOT/BOOTX64.EFI
rm tmp/grub.cfg
