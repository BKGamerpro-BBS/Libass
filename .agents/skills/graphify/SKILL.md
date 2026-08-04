---
name: graphify
description: Turn any codebase into an on-device queryable knowledge graph. Use when analyzing repo relationships, cross-module dependencies, or complex codebase architecture.
---

# Graphify Knowledge Graph Skill

Graphify parses code, docs, schemas, and configurations into a local, queryable knowledge graph without sending code to external vector databases.

## Commands & Usage

### 1. Build / Re-index Knowledge Graph
In the root directory of the workspace:
```cmd
graphify .
```

### 2. Natural Language Graph Queries
Search concepts, module workflows, or system architectures across the knowledge graph:
```cmd
graphify query "Explain authentication flow and wardrobe image handling"
```

### 3. Connection Paths Between Components
Explain how two code symbols or components connect:
```cmd
graphify path "AuthScreen" "ApiService"
```

### 4. Code Symbol Deep Dives
Detailed breakdown of a specific class, model, or route:
```cmd
graphify explain "WardrobeItem"
```

### 5. Memory & Reflection
Save useful query insights and reflect on stored repository knowledge:
```cmd
graphify reflect
```
