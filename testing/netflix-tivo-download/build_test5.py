#!/usr/bin/env python3
"""Reconstruct the exact signed test5 APK using the original test3 and this kit.

Python 3 standard library only. No downloads, signing keys, or Android build
tools are needed. The original APK is opened read-only.
"""
import argparse
import hashlib
import json
from pathlib import Path


def digest(path):
    h = hashlib.sha256()
    with path.open('rb') as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b''):
            h.update(block)
    return h.hexdigest()


def rebuild(input_apk, output_apk):
    kit = Path(__file__).resolve().parent
    manifest = json.loads((kit / 'test5-update.json').read_text())
    if manifest['format'] != 'netflix-tivo-copy-patch-v1':
        raise ValueError('Unsupported update format.')
    if digest(input_apk) != manifest['input_sha256']:
        raise ValueError('Expected the exact original Netflix-TiVo-test3.apk. Your file was not changed.')
    payload_path = kit / 'test5-update.bin'
    if digest(payload_path) != manifest['payload_sha256']:
        raise ValueError('Update data is damaged. Download the kit again.')
    if output_apk.exists():
        raise ValueError('Output already exists. Choose a new output filename.')
    with input_apk.open('rb') as source, payload_path.open('rb') as payload:
        # Exclusive creation protects an existing output, including the input APK.
        with output_apk.open('xb') as target:
            try:
                for op in manifest['operations']:
                    if len(op) != 1 or next(iter(op)) not in ('copy', 'data'):
                        raise ValueError('Invalid update operation.')
                    kind, (offset, remaining) = next(iter(op.items()))
                    stream = source if kind == 'copy' else payload
                    limit = input_apk.stat().st_size if kind == 'copy' else payload_path.stat().st_size
                    if offset < 0 or remaining < 0 or offset > limit or remaining > limit - offset:
                        raise ValueError('Update range is outside its source.')
                    if target.tell() + remaining > manifest['output_size']:
                        raise ValueError('Output exceeds the expected APK size.')
                    stream.seek(offset)
                    while remaining:
                        block = stream.read(min(remaining, 1024 * 1024))
                        if not block:
                            raise ValueError('Unexpected end of an input file.')
                        target.write(block)
                        remaining -= len(block)
                if target.tell() != manifest['output_size']:
                    raise ValueError('Output has an unexpected size.')
                target.flush()
                if digest(output_apk) != manifest['output_sha256']:
                    raise ValueError('Output failed checksum verification.')
            except BaseException:
                target.close()
                output_apk.unlink()
                raise
    print('SUCCESS:', output_apk)
    print('SHA-256:', manifest['output_sha256'])
    print('The exact signed test5 APK is ready. The original test3 file is unchanged.')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('input_apk', type=Path)
    parser.add_argument('--output', type=Path,
                        default=Path(__file__).resolve().with_name('Netflix-TiVo-test5.apk'))
    args = parser.parse_args()
    try:
        rebuild(args.input_apk, args.output)
    except (OSError, ValueError, KeyError, TypeError) as error:
        parser.exit(1, str(error) + '\n')


if __name__ == '__main__':
    main()
