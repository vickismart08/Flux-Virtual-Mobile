import sys
from pathlib import Path

def strip_comments(text: str) -> str:
    out = []
    i = 0
    n = len(text)
    in_s = None  # None, '"', "'"
    in_triple = False
    in_line_comment = False
    in_block_comment = False
    while i < n:
        ch = text[i]
        nxt = text[i+1] if i+1 < n else ''
        if in_line_comment:
            if ch == '\n':
                in_line_comment = False
                out.append(ch)
            i += 1
            continue
        if in_block_comment:
            if ch == '*' and nxt == '/':
                in_block_comment = False
                i += 2
            else:
                i += 1
            continue
        if in_s:
            out.append(ch)
            if ch == '\\':
                # escape next char
                if i+1 < n:
                    out.append(text[i+1])
                    i += 2
                    continue
            if in_triple:
                # check triple end
                if text.startswith(in_s*3, i):
                    out.append(in_s*2)
                    i += 3
                    in_s = None
                    in_triple = False
                    continue
            else:
                if ch == in_s:
                    in_s = None
            i += 1
            continue
        # not in string or comment
        if ch == '/' and nxt == '/':
            in_line_comment = True
            i += 2
            continue
        if ch == '/' and nxt == '*':
            in_block_comment = True
            i += 2
            continue
        if ch == '"' or ch == "'":
            # detect triple
            if text.startswith(ch*3, i):
                in_s = ch
                in_triple = True
                out.append(ch*3)
                i += 3
                continue
            else:
                in_s = ch
                out.append(ch)
                i += 1
                continue
        out.append(ch)
        i += 1
    return ''.join(out)


def process_file(p: Path):
    s = p.read_text(encoding='utf-8')
    new = strip_comments(s)
    if new != s:
        p.write_text(new, encoding='utf-8')


def main():
    base = Path('lib/screens')
    if not base.exists():
        return
    files = list(base.rglob('*.dart'))
    for f in files:
        process_file(f)

if __name__ == '__main__':
    main()
