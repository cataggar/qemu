#!/usr/bin/env python3

import argparse
import hashlib
import io
import json
import os
import tarfile
import tempfile
import urllib.request


def fetch(url):
    request = urllib.request.Request(url, headers={"User-Agent": "qemu-benchmark-input-lock/1"})
    with urllib.request.urlopen(request) as response:
        return response.read()


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def package_records(index_data):
    with tarfile.open(fileobj=io.BytesIO(index_data), mode="r:gz") as archive:
        text = archive.extractfile("APKINDEX").read().decode("utf-8")

    records = {}
    for block in text.split("\n\n"):
        fields = {}
        for line in block.splitlines():
            if ":" in line:
                key, value = line.split(":", 1)
                fields[key] = value
        if "P" in fields:
            records[fields["P"]] = fields
    return records


def refresh(lock):
    alpine = lock["alpine"]
    repository_records = {}

    for repository in lock["repositories"]:
        data = fetch(repository["url"])
        repository["sha256"] = sha256(data)
        repository_records[repository["repository"]] = package_records(data)

    for source in lock["sources"]:
        if source["kind"] == "package":
            record = repository_records[source["repository"]][source["package"]]
            source["version"] = record["V"]
            source["url"] = (
                f"{alpine['mirror']}/{alpine['branch']}/{source['repository']}/"
                f"{alpine['architecture']}/{source['package']}-{record['V']}.apk"
            )

        data = fetch(source["url"])
        source["sha256"] = sha256(data)
        source["size_bytes"] = len(data)


def write_atomic(path, lock):
    directory = os.path.dirname(os.path.abspath(path))
    fd, temporary = tempfile.mkstemp(prefix="inputs.lock.", suffix=".json", dir=directory)
    try:
        with os.fdopen(fd, "w", encoding="utf-8", newline="\n") as output:
            json.dump(lock, output, indent=2)
            output.write("\n")
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def main():
    parser = argparse.ArgumentParser(description="Refresh pinned Alpine benchmark inputs")
    parser.add_argument("lock_file")
    args = parser.parse_args()

    with open(args.lock_file, encoding="utf-8") as input_file:
        lock = json.load(input_file)
    if lock.get("schema") != 1:
        raise SystemExit("only input lock schema 1 is supported")

    refresh(lock)
    write_atomic(args.lock_file, lock)


if __name__ == "__main__":
    main()
