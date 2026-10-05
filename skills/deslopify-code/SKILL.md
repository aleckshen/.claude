---
name: deslopify-code
description: Review code changes in any language and remove AI-generated patterns like excessive comments, gratuitous defensive checks, type escape hatches, verbose logging, and over-engineering.
user-invocable: false
---

# Deslopify Code

Review code changes and remove AI-generated patterns that don't match human-written code. Applies to any language — the reference point is always the surrounding codebase, not a generic style guide.

## Usage

When asked to deslopify a branch, diff, or set of files, find and remove AI code slop in the changed lines only. If arguments name a base branch, commit range, or paths, use those as the target.

## What to Look For

### Excessive Comments

AI tends to over-comment. Remove comments that:
- State the obvious (e.g., "increment counter" above a counter increment)
- Repeat the function/variable name
- Are inconsistent with commenting patterns elsewhere in the file
- Explain *what* instead of *why*
- Add docstrings/doc blocks to trivial functions when the file doesn't do that elsewhere

```python
# ❌ Remove: States the obvious
# Check if the user is valid
if is_valid_user(user):

# ❌ Remove: Repeats the code
# Set the status to active
status = "active"

# ✅ Keep: Explains why
# Must check expiry before validation because expired tokens cause cryptic errors
if is_expired(token):
    return None
```

### Gratuitous Defensive Checks

Remove defensive code that doesn't match the codebase style, especially:
- Null/nil/None checks on values already validated upstream
- Runtime type checks on parameters the type system already guarantees
- Try/catch (or equivalent error swallowing) in trusted codepaths
- Redundant input validation in internal functions
- Fallback defaults for values that can't be missing

```go
// ❌ Remove if callers already validate
func processOrder(order *Order) error {
    if order == nil {
        return errors.New("order is required") // Caller already validates
    }
    // ...
}

// ✅ Keep: Validation at a system boundary (HTTP handler, CLI input, file parsing)
func handleRequest(w http.ResponseWriter, r *http.Request) {
    if r.Body == nil {
        http.Error(w, "missing body", http.StatusBadRequest)
        return
    }
    // ...
}
```

### Type Escape Hatches

AI often silences the type checker or compiler instead of fixing the types. Fix the types instead. Common forms:
- Casting to a top/dynamic type: `as any`, `Any`, `interface{}`/`any`, `Object`, `dynamic`
- Suppression directives: `@ts-ignore`, `# type: ignore`, `//nolint`, `@SuppressWarnings`, `#[allow(...)]`, `// eslint-disable`
- Forced unwraps or non-null assertions used to dodge a real case: `!`, `.unwrap()`, `!!`
- Unchecked casts where a type guard, pattern match, or proper type would work

```typescript
// ❌ Bad: Casting to any
const result = (data as any).value;

// ✅ Good: Fix the type or narrow it
if (hasValue(data)) {
    const result = data.value;
}
```

Keep a suppression only if it's genuinely necessary and the codebase does the same elsewhere.

### Style Inconsistencies

Check for patterns that differ from the rest of the file and codebase:
- Naming conventions (camelCase vs snake_case, prefixes, abbreviations)
- Import/include style
- Error handling patterns (exceptions vs return values vs result types)
- Comment style and density
- Formatting conventions the formatter doesn't enforce
- Idioms — non-idiomatic code for the language (e.g., index loops where the codebase uses iterators/comprehensions)

### Over-Engineering

Remove unnecessary abstractions:
- Wrapper functions that just call another function
- Interfaces/traits/protocols/abstract classes with only one implementation
- Generics/type parameters that aren't reused
- Helpers or utility functions used only once
- Config objects or options parameters for a single call site
- Speculative flexibility nobody asked for

```python
# ❌ Remove: Unnecessary wrapper
def get_item_count(items):
    return len(items)

# ❌ Remove: One-use options object
@dataclass
class ProcessingOptions:
    validate: bool

def process(data, options: ProcessingOptions): ...
# Only called once: process(data, ProcessingOptions(validate=True))
```

### Verbose Logging

AI adds excessive logging and print statements. Match the codebase's logging level and mechanism.

```javascript
// ❌ Remove if the file doesn't log at this level
console.log('Processing started');
console.log('Validating input...');
console.log('Input validated successfully');
console.log('Processing complete');

// ✅ Keep: Matches existing error logging pattern
logger.error(`Failed to process order ${orderId}: ${err.message}`);
```

## Review Process

1. **Get the diff**: Compare against the base branch (default branch unless told otherwise), including uncommitted changes
2. **Scan each changed file**: Look for the patterns above
3. **Check consistency**: Compare against unchanged portions of the same file and neighboring files
4. **Make targeted fixes**: Remove slop without changing behavior of correct code; don't touch lines outside the diff
5. **Verify**: Run the project's build, type checker, linter, or tests if available
6. **Summarize**: Report 1-3 sentences on what was changed

## Output Format

After reviewing, provide a brief summary:

```
Removed 3 redundant null checks in order_processor.go (upstream validation handles these).
Deleted 8 obvious comments and converted 2 unnecessary try/except blocks to let errors propagate.
```
