import os
import re

ROOT = os.path.join(os.path.dirname(__file__), '..', 'lib')


def import_path(filepath: str) -> str:
    rel = os.path.relpath(
        os.path.join(ROOT, 'core', 'widgets', 'app_snackbar.dart'),
        os.path.dirname(filepath),
    ).replace('\\', '/')
    return rel


def add_import(content: str, imp: str) -> str:
    if imp in content:
        return content
    lines = content.split('\n')
    last_imp = -1
    for i, line in enumerate(lines):
        if line.startswith('import '):
            last_imp = i
    if last_imp < 0:
        return f"import '{imp}';\n" + content
    lines.insert(last_imp + 1, f"import '{imp}';")
    return '\n'.join(lines)


PATTERNS = [
    (
        re.compile(
            r"ScaffoldMessenger\.of\(([^)]+)\)\s*\.showSnackBar\(\s*"
            r"const\s+SnackBar\(\s*content:\s*Text\((.+?)\)\s*,?\s*\)\s*,?\s*\)\s*;?",
            re.DOTALL,
        ),
        r"AppSnackBar.show(\1, \2);",
    ),
    (
        re.compile(
            r"ScaffoldMessenger\.of\(([^)]+)\)\s*\.showSnackBar\(\s*"
            r"SnackBar\(\s*content:\s*Text\((.+?)\)\s*,\s*backgroundColor:[\s\S]+?\)\s*,?\s*\)\s*;?",
            re.DOTALL,
        ),
        r"AppSnackBar.showError(\1, \2);",
    ),
    (
        re.compile(
            r"ScaffoldMessenger\.of\(([^)]+)\)\s*\.showSnackBar\(\s*"
            r"SnackBar\(\s*content:\s*Text\((.+?)\)\s*,?\s*\)\s*,?\s*\)\s*;?",
            re.DOTALL,
        ),
        r"AppSnackBar.show(\1, \2);",
    ),
    (
        re.compile(
            r"ScaffoldMessenger\.of\(([^)]+)\)\s*\.showSnackBar\(\s*"
            r"SnackBar\(\s*content:\s*Text\((.+?)\)\s*\)\s*,?\s*\)\s*;?",
            re.DOTALL,
        ),
        r"AppSnackBar.show(\1, \2);",
    ),
]


def migrate_file(path: str) -> bool:
    if path.replace('\\', '/').endswith('core/widgets/app_snackbar.dart'):
        return False

    with open(path, encoding='utf-8') as fh:
        content = fh.read()
    if 'ScaffoldMessenger.of' not in content:
        return False

    original = content
    changed = True
    while changed:
        changed = False
        for pattern, repl in PATTERNS:
            new_content, count = pattern.subn(repl, content)
            if count:
                content = new_content
                changed = True

    if content == original:
        return False

    content = add_import(content, import_path(path))
    with open(path, 'w', encoding='utf-8', newline='\n') as fh:
        fh.write(content)
    return True


def main() -> None:
    updated = []
    for dirpath, _, filenames in os.walk(ROOT):
        for name in filenames:
            if not name.endswith('.dart'):
                continue
            path = os.path.join(dirpath, name)
            if migrate_file(path):
                updated.append(path)

    print(f'Updated {len(updated)} files')
    for p in updated:
        print(' -', os.path.relpath(p, ROOT))


if __name__ == '__main__':
    main()
