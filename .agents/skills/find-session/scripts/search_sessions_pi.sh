#!/usr/bin/env bash
# Search and read Pi coding-agent session logs with minimal context cost.
#
# Pi-specific: this script's file-location logic and JSONL parsing target Pi's
# session-storage format exactly (see ../references/harness-pi.md). It will not
# work against another harness's transcript format; see
# ../references/adding-harness-support.md to add one.
#
# Two subcommands:
#   search  - find candidate session files matching one or more terms
#   show    - print a condensed (human-text-only) transcript of one session file
#
# Only reads the human-authored text of user/assistant/custom_message entries.
# Thinking-block `thinkingSignature` blobs, tool-call arguments, and raw tool
# results are never treated as searchable text, so base64 reasoning signatures
# can't produce false-positive matches.
#
# Requires: bash, jq, base64, find.

set -euo pipefail

# jq filter shared by search/show: emits one "role<TAB>base64(text)" line per
# human-text block in user/assistant/custom_message messages.
EXTRACT_FILTER='
select(.type=="message")
| .message as $m
| select($m.role=="user" or $m.role=="assistant" or $m.role=="custom_message")
| ( if ($m.content|type)=="string"
    then [$m.role, $m.content]
    else ($m.content // [])[] | select(.type=="text") | [$m.role, .text]
    end )
| [.[0], (.[1] | @base64)]
| @tsv
'

die() {
	echo "Error: $*" >&2
	exit 1
}

require_jq() {
	command -v jq >/dev/null 2>&1 || die "jq is required but not found on PATH."
}

expand_tilde() {
	local path="$1"
	case "$path" in
	"~"/*) printf '%s' "${HOME}${path:1}" ;;
	"~") printf '%s' "$HOME" ;;
	*) printf '%s' "$path" ;;
	esac
}

sessions_root() {
	if [[ -n "${PI_CODING_AGENT_SESSION_DIR:-}" ]]; then
		expand_tilde "$PI_CODING_AGENT_SESSION_DIR"
		return
	fi
	local config_dir="${PI_CODING_AGENT_DIR:-~/.pi/agent}"
	config_dir="$(expand_tilde "$config_dir")"
	printf '%s/sessions' "$config_dir"
}

find_session_files() {
	local root="$1"
	[[ -d "$root" ]] || return 0
	find "$root" -type f -name '*.jsonl' | sort
}

# Reads the header (first line) of a session file, prints "cwd<TAB>timestamp".
read_header() {
	local file="$1"
	head -n 1 "$file" 2>/dev/null |
		jq -r 'select(.type=="session") | [(.cwd // "unknown"), (.timestamp // "unknown")] | @tsv' \
			2>/dev/null || true
}

# Prints a ~100-char snippet around the first case-insensitive match of $2 in $1.
make_snippet() {
	local text="$1" term="$2" width=100
	local lower_text lower_term prefix_part idx start end excerpt pre_marker post_marker
	lower_text="${text,,}"
	lower_term="${term,,}"
	if [[ "$lower_text" != *"$lower_term"* ]]; then
		excerpt="${text:0:$width}"
		printf '%s' "${excerpt//$'\n'/ }"
		return
	fi
	prefix_part="${lower_text%%"$lower_term"*}"
	idx=${#prefix_part}
	start=$((idx - width / 2))
	((start < 0)) && start=0
	end=$((idx + ${#term} + width / 2))
	((end > ${#text})) && end=${#text}
	excerpt="${text:start:end-start}"
	excerpt="${excerpt//$'\n'/ }"
	pre_marker=""
	post_marker=""
	((start > 0)) && pre_marker="..."
	((end < ${#text})) && post_marker="..."
	printf '%s%s%s' "$pre_marker" "$excerpt" "$post_marker"
}

iso_to_epoch() {
	local ts="$1"
	# Strip fractional seconds; both BSD and GNU date accept the base ISO form.
	local trimmed="${ts%%.*}"
	[[ "$ts" == *.* ]] && trimmed="${trimmed}Z"
	date -u -d "$trimmed" +%s 2>/dev/null ||
		date -u -j -f '%Y-%m-%dT%H:%M:%SZ' "$trimmed" +%s 2>/dev/null || echo ""
}

usage() {
	cat <<'EOF'
Usage:
  search_sessions.sh search <term>... [--require-all] [--limit N] [--days N]
                     [--snippets-per-file N] [--cwd-filter STR] [--json]
  search_sessions.sh show <file> [--grep TERM]
EOF
}

cmd_search() {
	local -a terms=()
	local require_all=0 limit=15 days="" snippets_per_file=3 cwd_filter="" as_json=0

	while [[ $# -gt 0 ]]; do
		case "$1" in
		--require-all)
			require_all=1
			shift
			;;
		--limit)
			limit="$2"
			shift 2
			;;
		--days)
			days="$2"
			shift 2
			;;
		--snippets-per-file)
			snippets_per_file="$2"
			shift 2
			;;
		--cwd-filter)
			cwd_filter="$2"
			shift 2
			;;
		--json)
			as_json=1
			shift
			;;
		--)
			shift
			terms+=("$@")
			break
			;;
		-*)
			die "Unknown option: $1"
			;;
		*)
			terms+=("$1")
			shift
			;;
		esac
	done
	[[ ${#terms[@]} -gt 0 ]] || die "At least one search term is required."

	local root
	root="$(sessions_root)"
	local -a files=()
	while IFS= read -r f; do
		[[ -n "$f" ]] || continue
		if [[ -n "$cwd_filter" ]]; then
			shopt -s nocasematch
			[[ "$f" == *"$cwd_filter"* ]] || {
				shopt -u nocasematch
				continue
			}
			shopt -u nocasematch
		fi
		files+=("$f")
	done < <(find_session_files "$root")

	local cutoff=""
	if [[ -n "$days" ]]; then
		cutoff=$(($(date -u +%s) - days * 86400))
	fi

	local -a result_blocks=()
	local file
	for file in "${files[@]}"; do
		local header cwd header_ts
		header="$(read_header "$file")"
		cwd="${header%%$'\t'*}"
		header_ts="${header#*$'\t'}"
		[[ -n "$cwd" ]] || cwd="unknown"
		[[ -n "$header_ts" ]] || header_ts="unknown"

		if [[ -n "$cutoff" && "$header_ts" != "unknown" ]]; then
			local epoch
			epoch="$(iso_to_epoch "$header_ts")"
			if [[ -n "$epoch" ]] && ((epoch < cutoff)); then
				continue
			fi
		fi

		local -A matched=()
		local -a snippets=()
		local role b64text text term
		while IFS=$'\t' read -r role b64text; do
			[[ -n "$role" ]] || continue
			text="$(printf '%s' "$b64text" | base64 -d 2>/dev/null || true)"
			for term in "${terms[@]}"; do
				[[ -n "${matched[$term]:-}" ]] && continue
				shopt -s nocasematch
				if [[ "$text" == *"$term"* ]]; then
					shopt -u nocasematch
					matched[$term]=1
					if [[ ${#snippets[@]} -lt $snippets_per_file ]]; then
						snippets+=("[$role] $(make_snippet "$text" "$term")")
					fi
				else
					shopt -u nocasematch
				fi
			done
			[[ ${#matched[@]} -eq ${#terms[@]} ]] && break
		done < <(jq -r "$EXTRACT_FILTER" "$file" 2>/dev/null || true)

		local match_count=${#matched[@]}
		local hit=0
		if [[ $require_all -eq 1 ]]; then
			[[ $match_count -eq ${#terms[@]} ]] && hit=1
		else
			[[ $match_count -gt 0 ]] && hit=1
		fi
		[[ $hit -eq 1 ]] || continue

		local matched_terms
		matched_terms="$(printf '%s\n' "${!matched[@]}" | sort | paste -sd ',' -)"
		local snippets_joined=""
		local s
		for s in "${snippets[@]:-}"; do
			[[ -n "$s" ]] && snippets_joined+="${s}"$'\x1e'
		done

		result_blocks+=("${match_count}"$'\x1f'"${header_ts}"$'\x1f'"${file}"$'\x1f'"${cwd}"$'\x1f'"${matched_terms}"$'\x1f'"${snippets_joined}")
	done

	[[ ${#result_blocks[@]} -gt 0 ]] || {
		if [[ $as_json -eq 1 ]]; then
			echo "[]"
		else
			echo "No matches for [${terms[*]}] under $root"
		fi
		exit 1
	}

	# Sort by match_count desc, then timestamp desc.
	local sorted
	sorted="$(printf '%s\n' "${result_blocks[@]}" | sort -t$'\x1f' -k1,1nr -k2,2r)"
	sorted="$(printf '%s\n' "$sorted" | head -n "$limit")"

	if [[ $as_json -eq 1 ]]; then
		printf '['
		local first=1
		while IFS=$'\x1f' read -r match_count ts file cwd matched_terms snippets_joined; do
			[[ -n "$file" ]] || continue
			[[ $first -eq 1 ]] || printf ','
			first=0
			local terms_json snippets_json snippet_line
			terms_json="$(printf '%s' "$matched_terms" | tr ',' '\n' | jq -R . | jq -s .)"
			# BSD tr doesn't support \xHH escapes, so split on \x1e with a bash read loop instead.
			snippets_json="["
			local snippet_first=1
			while IFS= read -r -d $'\x1e' snippet_line; do
				[[ -n "$snippet_line" ]] || continue
				[[ $snippet_first -eq 1 ]] || snippets_json+=","
				snippet_first=0
				snippets_json+="$(jq -Rn --arg s "$snippet_line" '$s')"
			done <<<"${snippets_joined}"$'\x1e'
			snippets_json+="]"
			jq -n --arg path "$file" --arg cwd "$cwd" --arg ts "$ts" \
				--argjson match_count "$match_count" --argjson matched_terms "$terms_json" \
				--argjson snippets "$snippets_json" \
				'{path:$path, cwd:$cwd, timestamp:$ts, match_count:$match_count, matched_terms:$matched_terms, snippets:$snippets}'
		done <<<"$sorted"
		printf ']\n'
	else
		while IFS=$'\x1f' read -r match_count ts file cwd matched_terms snippets_joined; do
			[[ -n "$file" ]] || continue
			echo "### $file"
			echo "    cwd: $cwd  |  timestamp: $ts  |  matched: ${matched_terms//,/, }"
			local snippet
			while IFS= read -r -d $'\x1e' snippet; do
				[[ -n "$snippet" ]] && echo "    - $snippet"
			done <<<"${snippets_joined}"$'\x1e'
			echo
		done <<<"$sorted"
	fi
}

cmd_show() {
	local file="" grep_term=""
	while [[ $# -gt 0 ]]; do
		case "$1" in
		--grep)
			grep_term="$2"
			shift 2
			;;
		-*)
			die "Unknown option: $1"
			;;
		*)
			[[ -z "$file" ]] || die "Only one file may be given to 'show'."
			file="$(expand_tilde "$1")"
			shift
			;;
		esac
	done
	[[ -n "$file" ]] || die "A session file path is required."
	[[ -f "$file" ]] || die "File not found: $file"

	local printed=0
	local role b64text text
	while IFS=$'\t' read -r role b64text; do
		[[ -n "$role" ]] || continue
		text="$(printf '%s' "$b64text" | base64 -d 2>/dev/null || true)"
		if [[ -n "$grep_term" ]]; then
			shopt -s nocasematch
			[[ "$text" == *"$grep_term"* ]] || {
				shopt -u nocasematch
				continue
			}
			shopt -u nocasematch
		fi
		echo "--- $role ---"
		printf '%s\n\n' "$text"
		printed=$((printed + 1))
	done < <(jq -r "$EXTRACT_FILTER" "$file" 2>/dev/null || true)

	if [[ $printed -eq 0 ]]; then
		if [[ -n "$grep_term" ]]; then
			echo "No user/assistant text in $file matched '$grep_term'"
		else
			echo "No user/assistant text found in $file"
		fi
		exit 1
	fi
}

main() {
	require_jq
	[[ $# -gt 0 ]] || {
		usage
		exit 1
	}
	local command="$1"
	shift
	case "$command" in
	search) cmd_search "$@" ;;
	show) cmd_show "$@" ;;
	-h | --help) usage ;;
	*)
		usage
		die "Unknown command: $command"
		;;
	esac
}

main "$@"
