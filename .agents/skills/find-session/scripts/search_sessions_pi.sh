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
# Requires: bash, jq, fd.

set -euo pipefail

# jq filter shared by search/show: emits one role+text record per human-text
# block in user/assistant/custom_message messages, in a single pass over the
# whole file (one jq process per file, no per-block subprocess). Records are
# joined with \x1e and role/text within a record with \x1f; any of those
# control bytes occurring in real text are stripped since they can't survive
# as literal delimiters (real newlines are left intact).
EXTRACT_FILTER='
select(.type=="message")
| .message as $m
| select($m.role=="user" or $m.role=="assistant" or $m.role=="custom_message")
| ( if ($m.content|type)=="string"
    then [$m.role, $m.content]
    else ($m.content // [])[] | select(.type=="text") | [$m.role, .text]
    end )
| (.[0] | gsub("[\u001e\u001f]";" ")) as $role
| (.[1] | gsub("[\u001e\u001f]";" ")) as $text
| $role + "\u001f" + $text + "\u001e"
'

# Like EXTRACT_FILTER, but scans multiple files in a single jq process (jq
# treats concatenated file args as one continuous stream), tags every record
# with input_filename, and does term-matching itself (jq's C string ops beat a
# bash loop over tens of thousands of text blocks) so cmd_search's bash loop
# only ever sees records that already matched at least one term. $terms_json
# is supplied as an --argjson array of the original (as-typed) search terms;
# matching is case-insensitive via ascii_downcase on both sides. Hit terms for
# a record are joined with \u0001 (a byte that can't appear in a CLI term).
ALL_FILTER='
if .type=="session" then
  "H\u001f" + input_filename + "\u001f" + ((.cwd // "unknown")|tostring|gsub("[\u001e\u001f]";" ")) + "\u001f" + ((.timestamp // "unknown")|tostring|gsub("[\u001e\u001f]";" ")) + "\u001e"
elif .type=="message" then
  .message as $m
  | select($m.role=="user" or $m.role=="assistant" or $m.role=="custom_message")
  | ( if ($m.content|type)=="string"
      then [$m.role, $m.content]
      else ($m.content // [])[] | select(.type=="text") | [$m.role, .text]
      end )
  | (.[0] | gsub("[\u001e\u001f]";" ")) as $role
  | (.[1] | gsub("[\u001e\u001f]";" ")) as $text
  | ($text | ascii_downcase) as $lower
  | ($terms_json | map(select(. as $t | $lower | contains($t | ascii_downcase)))) as $hits
  | select(($hits|length) > 0)
  | "T\u001f" + input_filename + "\u001f" + $role + "\u001f" + ($hits | join("\u0001")) + "\u001f" + $text + "\u001e"
else empty end
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
	fd -t f -e jsonl . "$root" | sort
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

	# Built once, not per file: jq does the actual case-insensitive matching in
	# ALL_FILTER, so bash never loops over all terms per text block.
	local terms_json
	terms_json="$(printf '%s\n' "${terms[@]}" | jq -R . | jq -cs .)"

	local -a result_blocks=()
	if [[ ${#files[@]} -gt 0 ]]; then
		local cur_file="" cur_cwd="unknown" cur_ts="unknown" skip_file=0
		local -A matched=()
		local -a snippets=()
		local rectype fname role hits text rec epoch hit_term

		# Finalizes accumulated matches/snippets for cur_file into result_blocks,
		# then resets accumulators for the next file. Shares cmd_search's locals
		# (matched, snippets, cur_*) via bash's dynamic scoping.
		finalize_file() {
			[[ -n "$cur_file" ]] || return 0
			if [[ $skip_file -eq 0 ]]; then
				local match_count=${#matched[@]}
				local hit=0
				if [[ $require_all -eq 1 ]]; then
					[[ $match_count -eq ${#terms[@]} ]] && hit=1
				else
					[[ $match_count -gt 0 ]] && hit=1
				fi
				if [[ $hit -eq 1 ]]; then
					local matched_terms
					matched_terms="$(printf '%s\n' "${!matched[@]}" | sort | paste -sd ',' -)"
					local snippets_joined=""
					local s
					for s in "${snippets[@]:-}"; do
						[[ -n "$s" ]] && snippets_joined+="${s}"$'\x1e'
					done
					result_blocks+=("${match_count}"$'\x1f'"${cur_ts}"$'\x1f'"${cur_file}"$'\x1f'"${cur_cwd}"$'\x1f'"${matched_terms}"$'\x1f'"${snippets_joined}")
				fi
			fi
			matched=()
			snippets=()
		}

		while IFS= read -r -d $'\x1e' rec; do
			rectype="${rec%%$'\x1f'*}"
			rec="${rec#*$'\x1f'}"
			fname="${rec%%$'\x1f'*}"
			rec="${rec#*$'\x1f'}"

			if [[ "$fname" != "$cur_file" ]]; then
				finalize_file
				cur_file="$fname"
				cur_cwd="unknown"
				cur_ts="unknown"
				skip_file=0
			fi

			if [[ "$rectype" == "H" ]]; then
				cur_cwd="${rec%%$'\x1f'*}"
				cur_ts="${rec#*$'\x1f'}"
				[[ -n "$cur_cwd" ]] || cur_cwd="unknown"
				[[ -n "$cur_ts" ]] || cur_ts="unknown"
				if [[ -n "$cutoff" && "$cur_ts" != "unknown" ]]; then
					epoch="$(iso_to_epoch "$cur_ts")"
					[[ -n "$epoch" ]] && ((epoch < cutoff)) && skip_file=1
				fi
				continue
			fi

			[[ $skip_file -eq 1 ]] && continue

			role="${rec%%$'\x1f'*}"
			rec="${rec#*$'\x1f'}"
			hits="${rec%%$'\x1f'*}"
			text="${rec#*$'\x1f'}"
			[[ -n "$role" ]] || continue
			while IFS= read -r -d $'\x01' hit_term; do
				[[ -n "$hit_term" ]] || continue
				[[ -n "${matched[$hit_term]:-}" ]] && continue
				matched[$hit_term]=1
				if [[ ${#snippets[@]} -lt $snippets_per_file ]]; then
					snippets+=("[$role] $(make_snippet "$text" "$hit_term")")
				fi
			done <<<"${hits}"$'\x01'
		done < <(jq -j --argjson terms_json "$terms_json" "$ALL_FILTER" "${files[@]}" 2>/dev/null || true)
		finalize_file
	fi

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
	local role text rec
	while IFS= read -r -d $'\x1e' rec; do
		role="${rec%%$'\x1f'*}"
		text="${rec#*$'\x1f'}"
		[[ -n "$role" ]] || continue
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
	done < <(jq -j "$EXTRACT_FILTER" "$file" 2>/dev/null || true)

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
