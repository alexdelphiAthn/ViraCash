#!/usr/bin/env python3
"""Build the PostgreSQL bootstrap from the original MariaDB dump.

The source contains SQL programs inside INSERT string literals, so this module
uses a small lexer instead of global replacements.  The generated bootstrap
keeps identifiers unquoted: PostgreSQL folds them to lower case, while existing
Factuzam SQL can continue referring to them case-insensitively.
"""

from __future__ import annotations

import argparse
import hashlib
import re
from collections import Counter
from dataclasses import dataclass, field
from pathlib import Path


HERE = Path(__file__).resolve().parent
SOURCE = HERE / "factuzam_original.sql"
TARGET = HERE / "factuzam_original_postgresql.sql"
ROUTINE_FILES = (
    HERE / ".routines_pg_batch_api.sql",
    HERE / ".routines_pg_batch_dml.sql",
    HERE / ".routines_pg_batch_pivot.sql",
)
EPOCH_SENTINEL = "1970-01-01 00:00:00"


@dataclass
class ConversionState:
    tables: list[str] = field(default_factory=list)
    primary_keys: int = 0
    identities: list[tuple[str, str]] = field(default_factory=list)
    touch_tables: list[str] = field(default_factory=list)
    comments: list[tuple[str, str, str]] = field(default_factory=list)
    indexes: set[str] = field(default_factory=set)
    columns: dict[tuple[str, str], "ColumnInfo"] = field(default_factory=dict)
    repaired_nulls: list[tuple[str, str, str]] = field(default_factory=list)
    inserted_rows: int = 0


@dataclass(frozen=True)
class ColumnInfo:
    mysql_type: str
    not_null: bool
    has_nonnull_default: bool


def split_sql_statements(text: str) -> list[str]:
    """Split on semicolons outside MariaDB literals and comments."""
    result: list[str] = []
    start = 0
    i = 0
    state = "normal"
    while i < len(text):
        ch = text[i]
        nxt = text[i + 1] if i + 1 < len(text) else ""
        if state == "normal":
            if ch == "'":
                state = "single"
            elif ch == '"':
                state = "double"
            elif ch == "`":
                state = "backtick"
            elif ch == "-" and nxt == "-":
                state = "line_comment"
                i += 1
            elif ch == "#":
                state = "line_comment"
            elif ch == "/" and nxt == "*":
                state = "block_comment"
                i += 1
            elif ch == ";":
                result.append(text[start : i + 1])
                start = i + 1
        elif state == "single":
            if ch == "\\":
                i += 1
            elif ch == "'":
                if nxt == "'":
                    i += 1
                else:
                    state = "normal"
        elif state == "double":
            if ch == "\\":
                i += 1
            elif ch == '"':
                if nxt == '"':
                    i += 1
                else:
                    state = "normal"
        elif state == "backtick":
            if ch == "`":
                if nxt == "`":
                    i += 1
                else:
                    state = "normal"
        elif state == "line_comment":
            if ch in "\r\n":
                state = "normal"
        elif state == "block_comment":
            if ch == "*" and nxt == "/":
                state = "normal"
                i += 1
        i += 1
    if text[start:].strip():
        result.append(text[start:])
    return result


def without_sql_comments(text: str) -> str:
    """Remove comments outside literals, retaining newlines for readability."""
    out: list[str] = []
    i = 0
    state = "normal"
    while i < len(text):
        ch = text[i]
        nxt = text[i + 1] if i + 1 < len(text) else ""
        if state == "normal":
            if ch == "'":
                state = "single"
                out.append(ch)
            elif ch == '"':
                state = "double"
                out.append(ch)
            elif ch == "`":
                state = "backtick"
                out.append(ch)
            elif ch == "-" and nxt == "-":
                state = "line_comment"
                i += 1
            elif ch == "#":
                state = "line_comment"
            elif ch == "/" and nxt == "*":
                state = "block_comment"
                i += 1
            else:
                out.append(ch)
        elif state in {"single", "double", "backtick"}:
            out.append(ch)
            quote = {"single": "'", "double": '"', "backtick": "`"}[state]
            if ch == "\\" and state != "backtick" and i + 1 < len(text):
                i += 1
                out.append(text[i])
            elif ch == quote:
                if nxt == quote:
                    i += 1
                    out.append(text[i])
                else:
                    state = "normal"
        elif state == "line_comment":
            if ch in "\r\n":
                out.append(ch)
                state = "normal"
        elif state == "block_comment":
            if ch == "*" and nxt == "/":
                state = "normal"
                i += 1
            elif ch in "\r\n":
                out.append(ch)
        i += 1
    return "".join(out)


MYSQL_ESCAPES = {
    "0": "\x00",
    "b": "\b",
    "n": "\n",
    "r": "\r",
    "t": "\t",
    "Z": "\x1a",
    "\\": "\\",
    "'": "'",
    '"': '"',
    "%": "%",
    "_": "_",
}


def emit_pg_string(value: str, *, timestamp_sentinel: bool = False) -> str:
    if "\x00" in value:
        raise ValueError("PostgreSQL text values cannot contain NUL bytes")
    escaped = value.replace("'", "''")
    literal = f"'{escaped}'"
    if timestamp_sentinel and value == "0000-00-00 00:00:00":
        return f"TIMESTAMP '{EPOCH_SENTINEL}'"
    return literal


def read_mysql_string(text: str, start: int, quote: str) -> tuple[str, int]:
    value: list[str] = []
    i = start + 1
    while i < len(text):
        ch = text[i]
        nxt = text[i + 1] if i + 1 < len(text) else ""
        if ch == "\\":
            if not nxt:
                value.append("\\")
                i += 1
                continue
            value.append(MYSQL_ESCAPES.get(nxt, nxt))
            i += 2
            continue
        if ch == quote:
            if nxt == quote:
                value.append(quote)
                i += 2
                continue
            return "".join(value), i + 1
        value.append(ch)
        i += 1
    raise ValueError("Unterminated MariaDB string literal")


def convert_lexical(text: str, *, timestamp_sentinel: bool = False) -> str:
    """Convert MariaDB identifier/string quoting without touching string data."""
    out: list[str] = []
    i = 0
    while i < len(text):
        ch = text[i]
        if ch in {"'", '"'}:
            value, i = read_mysql_string(text, i, ch)
            out.append(emit_pg_string(value, timestamp_sentinel=timestamp_sentinel))
            continue
        if ch == "`":
            end = i + 1
            name: list[str] = []
            while end < len(text):
                if text[end] == "`":
                    if end + 1 < len(text) and text[end + 1] == "`":
                        name.append("`")
                        end += 2
                        continue
                    break
                name.append(text[end])
                end += 1
            if end >= len(text):
                raise ValueError("Unterminated MariaDB identifier")
            out.append("".join(name))
            i = end + 1
            continue
        if ch == "0" and i + 2 < len(text) and text[i + 1] in {"x", "X"}:
            end = i + 2
            while end < len(text) and text[end] in "0123456789abcdefABCDEF":
                end += 1
            if end > i + 2:
                hex_value = text[i + 2 : end]
                out.append(f"decode('{hex_value}', 'hex')")
                i = end
                continue
        out.append(ch)
        i += 1
    return "".join(out)


def pg_type_syntax(text: str) -> str:
    replacements = (
        (r"\btinyint\s*\(\s*\d+\s*\)", "smallint"),
        (r"\bmediumint\s*\(\s*\d+\s*\)", "integer"),
        (r"\bbigint\s*\(\s*\d+\s*\)", "bigint"),
        (r"\bint\s*\(\s*\d+\s*\)", "integer"),
        (r"\bdecimal\b", "numeric"),
        (r"\bdouble\s+precision\b", "double precision"),
        (r"\bdouble\b", "double precision"),
        (r"\bfloat\b", "real"),
        (r"\btimestamp(?:\s*(\(\s*\d+\s*\)))?", r"timestamp\1 without time zone"),
        (r"\bdatetime(?:\s*(\(\s*\d+\s*\)))?", r"timestamp\1 without time zone"),
        (r"\b(?:tinytext|mediumtext|longtext)\b", "text"),
        (r"\b(?:tinyblob|mediumblob|longblob|blob)\b", "bytea"),
        (r"\b(?:varbinary|binary)\s*\(\s*\d+\s*\)", "bytea"),
    )
    for pattern, replacement in replacements:
        text = re.sub(pattern, replacement, text, flags=re.IGNORECASE)
    text = re.sub(
        r"\bcurrent_timestamp\s*\(\s*\)",
        "statement_timestamp()",
        text,
        flags=re.IGNORECASE,
    )
    return text


def convert_create_table(statement: str, state: ConversionState) -> str:
    statement = convert_lexical(statement)
    match = re.search(r"(?is)\bCREATE\s+TABLE\s+([A-Za-z_][\w$]*)\s*\(", statement)
    if not match:
        raise ValueError("Could not read CREATE TABLE header")
    table = match.group(1)
    state.tables.append(table)
    if re.search(r"(?im)^\s*PRIMARY\s+KEY\s*\(", statement):
        state.primary_keys += 1
    lines = statement.strip().splitlines()
    converted: list[str] = []
    for line in lines:
        column = re.match(r"^(\s*)([A-Za-z_][\w$]*)\s+(.+?)(,?)\s*$", line)
        if not column or column.group(2).upper() in {
            "CREATE",
            "PRIMARY",
            "UNIQUE",
            "CONSTRAINT",
            "FOREIGN",
            "CHECK",
        }:
            converted.append(pg_type_syntax(line))
            continue

        indent, name, definition, comma = column.groups()
        comment_match = re.search(
            r"(?is)\s+COMMENT\s+('(?:''|[^'])*')\s*$", definition
        )
        if comment_match:
            literal = comment_match.group(1)
            comment = literal[1:-1].replace("''", "'")
            state.comments.append((table, name, comment))
            definition = definition[: comment_match.start()].rstrip()

        mysql_type_match = re.match(r"([A-Za-z]+)", definition)
        if not mysql_type_match:
            raise ValueError(f"Could not read type for {table}.{name}")
        mysql_type = mysql_type_match.group(1).lower()
        not_null = bool(re.search(r"\bNOT\s+NULL\b", definition, re.I))
        default_match = re.search(
            r"(?is)\bDEFAULT\s+(?!NULL\b)(.+?)(?=\s+(?:ON\s+UPDATE|COMMENT|AUTO_INCREMENT|PRIMARY|UNIQUE|CHECK)\b|$)",
            definition,
        )
        state.columns[(table.lower(), name.lower())] = ColumnInfo(
            mysql_type=mysql_type,
            not_null=not_null,
            has_nonnull_default=bool(default_match),
        )

        had_auto_increment = bool(re.search(r"\bAUTO_INCREMENT\b", definition, re.I))
        had_on_update = bool(
            re.search(r"\bON\s+UPDATE\s+CURRENT_TIMESTAMP(?:\s*\(\s*\))?", definition, re.I)
        )
        was_unsigned = bool(re.search(r"\bUNSIGNED\b", definition, re.I))
        was_tinyint = bool(re.search(r"\bTINYINT\b", definition, re.I))

        definition = re.sub(r"\bAUTO_INCREMENT\b", "", definition, flags=re.I)
        definition = re.sub(
            r"\bON\s+UPDATE\s+CURRENT_TIMESTAMP(?:\s*\(\s*\))?",
            "",
            definition,
            flags=re.I,
        )
        definition = re.sub(r"\bUNSIGNED\b", "", definition, flags=re.I)
        definition = pg_type_syntax(definition)
        definition = re.sub(
            r"DEFAULT\s+'0000-00-00 00:00:00'",
            f"DEFAULT TIMESTAMP '{EPOCH_SENTINEL}'",
            definition,
            flags=re.I,
        )
        definition = re.sub(r"\s{2,}", " ", definition).strip()
        if had_auto_increment:
            definition = re.sub(
                r"^((?:smallint|integer|bigint)\b)",
                r"\1 GENERATED BY DEFAULT AS IDENTITY",
                definition,
                count=1,
                flags=re.I,
            )
            state.identities.append((table, name))
        if was_unsigned:
            if was_tinyint:
                definition += f" CHECK ({name} BETWEEN 0 AND 255)"
            else:
                definition += f" CHECK ({name} >= 0)"
        if had_on_update and table not in state.touch_tables:
            state.touch_tables.append(table)
        converted.append(f"{indent}{name} {definition}{comma}")

    result = "\n".join(converted)
    result = re.sub(r"\)\s*;\s*$", ");", result)
    return result


def convert_index(statement: str, state: ConversionState) -> str:
    code = convert_lexical(statement).strip()
    match = re.fullmatch(
        r"(?is)ALTER\s+TABLE\s+(\w+)\s+ADD\s+(UNIQUE\s+)?INDEX\s+"
        r"(\w+)\s*\((.*?)\)\s*;",
        code,
    )
    if not match:
        raise ValueError(f"Unsupported index statement: {code[:160]}")
    table, unique, original_name, columns = match.groups()
    name = original_name.lower()
    if name in state.indexes:
        name = f"{table}_{name}".lower()
    if len(name) > 63:
        name = name[:63]
    suffix = 2
    candidate = name
    while candidate in state.indexes:
        ending = f"_{suffix}"
        candidate = name[: 63 - len(ending)] + ending
        suffix += 1
    name = candidate
    state.indexes.add(name)
    keyword = "UNIQUE " if unique else ""
    return f"CREATE {keyword}INDEX {name} ON {table} ({columns});"


def implicit_value_for_mysql_type(mysql_type: str) -> str:
    if mysql_type in {"timestamp", "datetime", "date"}:
        if mysql_type == "date":
            return "DATE '1970-01-01'"
        return f"TIMESTAMP '{EPOCH_SENTINEL}'"
    if mysql_type in {
        "tinyint",
        "smallint",
        "mediumint",
        "int",
        "integer",
        "bigint",
        "decimal",
        "numeric",
        "float",
        "double",
        "real",
    }:
        return "0"
    if mysql_type in {"blob", "tinyblob", "mediumblob", "longblob", "binary", "varbinary"}:
        return "decode('', 'hex')"
    return "''"


def extract_value_rows(text: str) -> list[str]:
    rows: list[str] = []
    i = 0
    while i < len(text):
        while i < len(text) and (text[i].isspace() or text[i] == ","):
            i += 1
        if i >= len(text):
            break
        if text[i] != "(":
            raise ValueError(f"Expected INSERT row at: {text[i:i + 80]}")
        close = function_call_bounds(text, i)
        rows.append(text[i + 1 : close])
        i = close + 1
    return rows


def normalize_insert(statement: str, state: ConversionState) -> str:
    code = convert_lexical(statement, timestamp_sentinel=True).strip()
    match = re.match(
        r"(?is)^INSERT\s+INTO\s+(\w+)\s*\((.*?)\)\s*VALUES\s*(.*);\s*$",
        code,
    )
    if not match:
        raise ValueError(f"Unsupported INSERT statement: {code[:180]}")
    table, column_text, value_text = match.groups()
    columns = [column.strip() for column in split_top_level(column_text)]
    output_rows: list[str] = []
    for row_text in extract_value_rows(value_text):
        values = split_top_level(row_text)
        if len(values) != len(columns):
            raise ValueError(
                f"INSERT {table}: {len(columns)} columns but {len(values)} values"
            )
        for index, (column, value) in enumerate(zip(columns, values)):
            info = state.columns.get((table.lower(), column.lower()))
            if info and info.not_null and value.upper() == "NULL":
                replacement = (
                    "DEFAULT"
                    if info.has_nonnull_default
                    else implicit_value_for_mysql_type(info.mysql_type)
                )
                values[index] = replacement
                state.repaired_nulls.append((table, column, replacement))
        output_rows.append(f"  ({', '.join(values)})")
    state.inserted_rows += len(output_rows)
    return (
        f"INSERT INTO {table} ({', '.join(columns)}) VALUES\n"
        + ",\n".join(output_rows)
        + ";"
    )


def function_call_bounds(text: str, open_paren: int) -> int:
    depth = 1
    i = open_paren + 1
    while i < len(text):
        ch = text[i]
        if ch == "'":
            _, i = read_pg_string(text, i)
            continue
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
            if depth == 0:
                return i
        i += 1
    raise ValueError("Unbalanced function call")


def read_pg_string(text: str, start: int) -> tuple[str, int]:
    value: list[str] = []
    i = start + 1
    while i < len(text):
        if text[i] == "'":
            if i + 1 < len(text) and text[i + 1] == "'":
                value.append("'")
                i += 2
                continue
            return "".join(value), i + 1
        value.append(text[i])
        i += 1
    raise ValueError("Unterminated PostgreSQL string")


def split_top_level(text: str, separator: str = ",") -> list[str]:
    parts: list[str] = []
    start = 0
    depth = 0
    i = 0
    while i < len(text):
        if text[i] == "'":
            _, i = read_pg_string(text, i)
            continue
        if text[i] == "(":
            depth += 1
        elif text[i] == ")":
            depth -= 1
        elif depth == 0 and text.startswith(separator, i):
            parts.append(text[start:i].strip())
            start = i + len(separator)
            i = start
            continue
        i += 1
    parts.append(text[start:].strip())
    return parts


def find_top_level_phrase(text: str, phrase: str) -> int:
    depth = 0
    i = 0
    lower = text.lower()
    phrase_lower = phrase.lower()
    while i < len(text):
        if text[i] == "'":
            _, i = read_pg_string(text, i)
            continue
        if text[i] == "(":
            depth += 1
        elif text[i] == ")":
            depth -= 1
        elif depth == 0 and lower.startswith(phrase_lower, i):
            return i
        i += 1
    return -1


def rewrite_named_calls(text: str, name: str, handler) -> str:
    pattern = re.compile(rf"\b{re.escape(name)}\s*\(", re.I)
    search_from = 0
    while True:
        match = pattern.search(text, search_from)
        if not match:
            return text
        open_paren = text.find("(", match.start())
        close_paren = function_call_bounds(text, open_paren)
        inner = text[open_paren + 1 : close_paren]
        replacement = handler(inner)
        text = text[: match.start()] + replacement + text[close_paren + 1 :]
        search_from = match.start() + len(replacement)


def rewrite_group_concat(inner: str) -> str:
    separator_at = find_top_level_phrase(inner, " separator ")
    if separator_at >= 0:
        value_part = inner[:separator_at]
        separator = inner[separator_at + len(" separator ") :].strip()
    else:
        value_part = inner
        separator = "','"
    order_at = find_top_level_phrase(value_part, " order by ")
    if order_at >= 0:
        expression = value_part[:order_at].strip()
        order = value_part[order_at + len(" order by ") :].strip()
    else:
        expression = value_part.strip()
        order = ""
    arguments = split_top_level(expression)
    if len(arguments) > 1:
        # MariaDB CONCAT returns NULL when any argument is NULL.  PostgreSQL's
        # concat() skips NULL values, while the || operator preserves this rule.
        expression = " || ".join(f"({argument})::text" for argument in arguments)
    order_sql = f" ORDER BY {order}" if order else ""
    return f"string_agg(({expression})::text, {separator}{order_sql})"


def rewrite_concat(inner: str) -> str:
    arguments = split_top_level(inner)
    if not arguments:
        raise ValueError("CONCAT requires at least one argument")
    # Unlike PostgreSQL concat(), MariaDB CONCAT() propagates NULL.
    return "(" + " || ".join(f"({argument})::text" for argument in arguments) + ")"


def rewrite_date_format(inner: str) -> str:
    args = split_top_level(inner)
    if len(args) != 2:
        raise ValueError(f"Unsupported DATE_FORMAT call: {inner}")
    format_value, _ = read_pg_string(args[1], 0)
    pg_format = format_value
    for source, target in (
        ("%Y", "YYYY"),
        ("%m", "MM"),
        ("%d", "DD"),
        ("%H", "HH24"),
        ("%i", "MI"),
        ("%s", "SS"),
    ):
        pg_format = pg_format.replace(source, target)
    return f"to_char({args[0]}, {emit_pg_string(pg_format)})"


def rewrite_format(inner: str) -> str:
    args = split_top_level(inner)
    if len(args) < 2 or not re.fullmatch(r"\d+", args[1]):
        raise ValueError(f"Unsupported FORMAT call: {inner}")
    decimals = int(args[1])
    # MariaDB FORMAT() always emits grouping separators.  Literal ',' and '.'
    # in a PostgreSQL to_char mask keep the en-US punctuation used by MariaDB
    # when no locale argument is supplied.
    mask = "FM999,999,999,999,999,990"
    if decimals:
        mask += "." + ("0" * decimals)
    return f"to_char({args[0]}, {emit_pg_string(mask)})"


def rewrite_to_days(inner: str) -> str:
    return f"(({inner})::date - DATE '0001-01-01' + 366)"


def convert_view(statement: str) -> tuple[str, str]:
    code = convert_lexical(without_sql_comments(statement)).strip()
    match = re.match(
        r"(?is)CREATE\s+ALGORITHM\s*=\s*UNDEFINED\s+VIEW\s+(\w+)\s+AS\s+(.*);\s*$",
        code,
    )
    if not match:
        raise ValueError(f"Unsupported view statement: {code[:160]}")
    name, query = match.groups()
    query = re.sub(r"!\s*exists\b", "NOT EXISTS", query, flags=re.I)
    query = re.sub(
        r"\bcurdate\s*\(\s*\)",
        "(statement_timestamp()::date)",
        query,
        flags=re.I,
    )
    query = re.sub(r"\bifnull\s*\(", "coalesce(", query, flags=re.I)
    query = rewrite_named_calls(query, "group_concat", rewrite_group_concat)
    query = rewrite_named_calls(query, "concat", rewrite_concat)
    query = rewrite_named_calls(query, "date_format", rewrite_date_format)
    query = rewrite_named_calls(query, "format", rewrite_format)
    query = rewrite_named_calls(query, "to_days", rewrite_to_days)
    # A view does not promise row order.  Consumers that need ordering must add
    # an explicit, total ORDER BY of their own.
    order_at = find_top_level_phrase(query, " order by ")
    if order_at >= 0:
        query = query[:order_at].rstrip()
    return name, f"CREATE OR REPLACE VIEW {name} AS\n{query};"


def trigger_sql(state: ConversionState) -> str:
    if not state.touch_tables:
        return ""
    lines = [
        "CREATE OR REPLACE FUNCTION factuzam_touch_instantemodif()",
        "RETURNS trigger",
        "LANGUAGE plpgsql",
        "AS $factuzam$",
        "BEGIN",
        "  IF NEW.instantemodif IS NOT DISTINCT FROM OLD.instantemodif",
        "     AND (to_jsonb(NEW) - 'instantemodif')",
        "         IS DISTINCT FROM (to_jsonb(OLD) - 'instantemodif') THEN",
        "    NEW.instantemodif := statement_timestamp();",
        "  END IF;",
        "  RETURN NEW;",
        "END;",
        "$factuzam$;",
        "",
    ]
    for table in state.touch_tables:
        name = f"trg_{table}_instantemodif"
        if len(name) > 63:
            name = name[:63]
        lines.extend(
            [
                f"DROP TRIGGER IF EXISTS {name} ON {table};",
                f"CREATE TRIGGER {name}",
                f"BEFORE UPDATE ON {table}",
                "FOR EACH ROW",
                "EXECUTE FUNCTION factuzam_touch_instantemodif();",
                "",
            ]
        )
    return "\n".join(lines).rstrip()


def identity_reset_sql(state: ConversionState) -> str:
    lines: list[str] = []
    for table, column in state.identities:
        sequence_table = table.lower()
        sequence_column = column.lower()
        lines.extend(
            [
                "SELECT setval(",
                f"  pg_get_serial_sequence('{sequence_table}', '{sequence_column}'),",
                f"  COALESCE(MAX({column}), 1),",
                f"  MAX({column}) IS NOT NULL",
                f") FROM {table};",
            ]
        )
    return "\n".join(lines)


def comment_sql(state: ConversionState) -> str:
    return "\n".join(
        f"COMMENT ON COLUMN {table}.{column} IS {emit_pg_string(comment)};"
        for table, column, comment in state.comments
    )


def build() -> str:
    source_bytes = SOURCE.read_bytes()
    source_hash = hashlib.sha256(source_bytes).hexdigest()
    source = source_bytes.decode("utf-8-sig")
    views_marker = source.index("-- VISTAS")
    routines_marker = source.index("-- PROCEDIMIENTOS ALMACENADOS")
    table_text = source[:views_marker]
    view_text = source[views_marker:routines_marker]
    routine_text = source[routines_marker:]

    view_definitions: list[tuple[str, str]] = []
    for raw in split_sql_statements(view_text):
        code = without_sql_comments(raw).strip()
        if re.match(r"(?is)^CREATE\s+ALGORITHM", code):
            view_definitions.append(convert_view(raw))

    state = ConversionState()
    table_output: list[str] = []
    for raw in split_sql_statements(table_text):
        code = without_sql_comments(raw).strip()
        if not code or code == ";":
            continue
        if re.match(r"(?is)^DROP\s+TABLE\s+IF\s+EXISTS", code):
            converted = convert_lexical(code)
            converted = re.sub(r";\s*$", " CASCADE;", converted)
            name_match = re.search(r"(?i)EXISTS\s+([A-Za-z_]\w*)", converted)
            if name_match:
                table_output.extend(["", f"-- Tabla: {name_match.group(1)}"])
            table_output.append(converted)
        elif re.match(r"(?is)^CREATE\s+TABLE", code):
            table_output.append(convert_create_table(code, state))
        elif re.match(r"(?is)^ALTER\s+TABLE.*?ADD\s+(?:UNIQUE\s+)?INDEX", code):
            table_output.append(convert_index(code, state))
        elif re.match(r"(?is)^INSERT\s+INTO", code):
            table_output.append(normalize_insert(code, state))
        elif re.match(r"(?is)^(?:START\s+TRANSACTION|COMMIT|SET\b)", code):
            continue
        else:
            raise ValueError(f"Unsupported table/data statement: {code[:180]}")

    routine_names = re.findall(
        r"(?im)^DROP\s+PROCEDURE\s+IF\s+EXISTS\s+`?([^`;\s]+)", routine_text
    )
    if len(routine_names) != 45:
        raise ValueError(f"Expected 45 source routines, found {len(routine_names)}")

    routine_parts: list[str] = []
    routine_hash_parts: list[str] = []
    for routine_file in ROUTINE_FILES:
        part = routine_file.read_bytes().decode("utf-8-sig").strip()
        logical_part = part.replace("\r\n", "\n")
        routine_parts.append(f"-- Módulo: {routine_file.name}\n{logical_part}")
        routine_hash_parts.append(f"{routine_file.name}\n{logical_part}\n")
    routine_sql = "\n\n".join(routine_parts)
    # Hash the logical LF form plus each file name, so provenance is stable
    # across Git platforms and also detects module reordering.
    routine_hash = hashlib.sha256(
        "".join(routine_hash_parts).encode("utf-8")
    ).hexdigest()
    translated_routine_matches = re.findall(
        r"(?im)^CREATE(?:\s+OR\s+REPLACE)?\s+(?:PROCEDURE|FUNCTION)\s+([a-z_]\w*)\s*\(",
        routine_sql,
    )
    translated_routine_names = {
        name.casefold()
        for name in translated_routine_matches
    }
    missing_routines = sorted(
        name for name in routine_names if name.casefold() not in translated_routine_names
    )
    if missing_routines:
        raise ValueError(
            "Missing PostgreSQL routine adapters: " + ", ".join(missing_routines)
        )
    if len(translated_routine_matches) != 45 or len(translated_routine_names) != 45:
        raise ValueError(
            "Expected exactly 45 unique PostgreSQL routine adapters, found "
            f"{len(translated_routine_matches)} definitions / "
            f"{len(translated_routine_names)} unique names"
        )

    expected_inventory = {
        "tables": (len(state.tables), 66),
        "primary keys": (state.primary_keys, 65),
        "indexes": (len(state.indexes), 77),
        "identity columns": (len(state.identities), 10),
        "touch triggers": (len(state.touch_tables), 47),
        "column comments": (len(state.comments), 249),
        "views": (len(view_definitions), 50),
        "inserted rows": (state.inserted_rows, 7063),
    }
    mismatches = [
        f"{label}: expected {expected}, found {actual}"
        for label, (actual, expected) in expected_inventory.items()
        if actual != expected
    ]
    if mismatches:
        raise ValueError("Source inventory changed; " + "; ".join(mismatches))

    repaired_summary = Counter(state.repaired_nulls)
    repaired_lines = [
        "-- Desglose de coerciones NULL incompatibles (tabla.columna -> valor: filas):",
        *(
            f"--   {table}.{column} -> {replacement}: {count}"
            for (table, column, replacement), count in sorted(repaired_summary.items())
        ),
    ]

    lines = [
        "-- ============================================================================",
        "-- Factuzam: bootstrap PostgreSQL (fase 2)",
        "-- Generado desde factuzam_original.sql (volcado MariaDB).",
        f"-- SHA-256 del origen: {source_hash}",
        f"-- SHA-256 canónico de los módulos de rutinas PostgreSQL: {routine_hash}",
        "-- Objetivo: PostgreSQL 16 o posterior; codificación UTF-8.",
        "-- Dependencia: extensión contrib trusted unaccent.",
        "-- Alcance: tablas, datos, índices, comentarios, triggers, vistas y 45 rutinas.",
        "-- Los resultsets dinámicos se exponen mediante refcursor (CALL + FETCH en una transacción).",
        "-- Las rutinas no hacen COMMIT/ROLLBACK interno: participan en la transacción llamadora.",
        "-- Los identificadores se crean sin comillas y PostgreSQL los normaliza a minúsculas.",
        "-- DATETIME/TIMESTAMP se convierten a timestamp without time zone.",
        "-- La colación queda en la configurada para la base PostgreSQL de destino.",
        "-- Los ORDER BY superiores de las vistas se omiten; el consumidor debe ordenar.",
        "-- El SQL MariaDB almacenado como datos se conserva literalmente, sin traducir.",
        f"-- Las fechas cero de MariaDB se conservan con el centinela {EPOCH_SENTINEL}.",
        f"-- NULL explícitos incompatibles con NOT NULL normalizados: {len(state.repaired_nulls)}.",
        *repaired_lines,
        "-- ============================================================================",
        "",
        "BEGIN;",
        "SET LOCAL search_path = public;",
        "SET LOCAL client_encoding = 'UTF8';",
        "SET LOCAL standard_conforming_strings = on;",
        "SET LOCAL check_function_bodies = on;",
        "CREATE EXTENSION IF NOT EXISTS unaccent WITH SCHEMA public;",
        "",
        "-- Eliminar primero las vistas conocidas para que el script pueda repetirse.",
    ]
    lines.extend(f"DROP VIEW IF EXISTS {name} CASCADE;" for name, _ in view_definitions)
    lines.extend(
        [
            "",
            "-- ============================================================================",
            "-- TABLAS, ÍNDICES Y DATOS",
            "-- ============================================================================",
            *table_output,
            "",
            "-- ============================================================================",
            "-- COMENTARIOS DE COLUMNAS",
            "-- ============================================================================",
            comment_sql(state),
            "",
            "-- ============================================================================",
            "-- SEMÁNTICA ON UPDATE CURRENT_TIMESTAMP",
            "-- ============================================================================",
            trigger_sql(state),
            "",
            "-- ============================================================================",
            "-- AJUSTE DE SECUENCIAS IDENTITY TRAS INSERTAR CLAVES EXPLÍCITAS",
            "-- ============================================================================",
            identity_reset_sql(state),
            "",
            "-- ============================================================================",
            "-- VISTAS",
            "-- ============================================================================",
        ]
    )
    for _, definition in view_definitions:
        lines.extend([definition, ""])
    lines.extend(
        [
            "-- ============================================================================",
            "-- RUTINAS",
            "-- ============================================================================",
            routine_sql,
            "",
            "COMMIT;",
            "",
        ]
    )
    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Genera y verifica el bootstrap PostgreSQL de Factuzam."
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="comprueba que el SQL versionado coincide con una regeneración limpia",
    )
    args = parser.parse_args()

    # Source string literals can contain physical CRLF.  Normalize those pairs
    # before TextIO applies the repository-wide CRLF policy; otherwise each
    # embedded CRLF would be written as CRCRLF and its stored value would change.
    output = build().replace("\r\n", "\n")
    if args.check:
        expected = output.replace("\n", "\r\n").encode("utf-8")
        actual = TARGET.read_bytes() if TARGET.exists() else b""
        if actual != expected:
            raise SystemExit(
                f"{TARGET} is stale; regenerate it with {Path(__file__).name}"
            )
        print(f"Verified {TARGET} ({len(output):,} characters)")
        return
    TARGET.write_text(output, encoding="utf-8", newline="\r\n")
    print(f"Generated {TARGET} ({len(output):,} characters)")


if __name__ == "__main__":
    main()
