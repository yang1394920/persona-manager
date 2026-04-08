# persona-manager

Manage user personas to help the AI understand who you are.

## Usage

**Set your persona:**

```
/setpersona <name> <description>
```

**Show current persona:**

```
/showpersona
```

**Switch persona:**

```
/usepersona <name>
```

**List all personas:**

```
/listpersonas
```

**Combine personas:**

```
/combine <name1,name2,...> [as <new_name>]
```

## Auto-Evolution Mode (自动迭代进化)

Enable auto-evolution to let the AI observe your behavior and automatically refine the active persona:

```
/evolve on          # Enable auto-evolution
/evolve off         # Disable auto-evolution
/evolve status      # Check evolution status
/evolve now         # Manually trigger evolution analysis
```

When enabled, the AI will:
- Observe your reactions to different response styles
- Note preferences you express (likes/dislikes)
- Automatically update the active persona description
- Learn from correction patterns

## AI-Created Personas (AI自主创造)

Let the AI analyze conversation and create personas:

```
/analyze-me                    # Analyze your behavior and suggest personas
/create-from-chat <name>       # Create persona from recent conversation
/detect-persona                # AI guesses which preset fits you best
```

The AI can:
- Detect patterns in your questions and feedback
- Suggest new personas based on observed traits
- Propose combinations that might fit you
- Recommend persona switches when it detects mismatches

## Storage

Personas are stored in `personas/` directory within the skill folder. Each persona is a JSON file containing:
- name: Persona identifier
- description: Full persona description
- tags: Optional tags for categorization
- created: Timestamp
- updated: Timestamp
- autoEvolve: Boolean flag for auto-evolution
- evolutionLog: Array of past evolution changes

## Single Persona Example

```json
{
  "name": "work",
  "description": "Software engineer focused on backend architecture. Prefers concise explanations. Dislikes small talk. Wants technical depth over surface-level summaries.",
  "tags": ["professional", "technical"],
  "created": "2026-04-08T13:00:00Z",
  "updated": "2026-04-08T13:00:00Z",
  "autoEvolve": true,
  "evolutionLog": [
    {"time": "2026-04-08T14:00:00Z", "change": "Added: dislikes emojis in technical answers"}
  ]
}
```

## Combined Persona Example

When combining "work" + "creative":

```
/combine work,creative as work-creative
```

Creates a merged persona that blends both descriptions.

## How It Works

When a persona is active, the skill injects the persona description into the system context, helping the AI model understand:
- Your communication preferences
- Your background and expertise
- Your style (concise vs detailed, formal vs casual)
- What you care about / find annoying

This affects how the AI responds to you without changing the underlying model.

## Auto-Evolution Rules

The AI should observe and evolve personas based on:

1. **Explicit feedback**: "太长了" → Add " prefers very short answers"
2. **Implicit signals**: Asking follow-up "能不能再详细点" → Add " sometimes wants more detail"
3. **Topic patterns**: Frequently asking about costs → Strengthen "cost-conscious" trait
4. **Tone reactions**: Positive response to humor → Add " appreciates wit"
5. **Correction patterns**: "不对，你应该..." → Update technical depth preference

Evolution should be conservative - accumulate evidence before making changes.
