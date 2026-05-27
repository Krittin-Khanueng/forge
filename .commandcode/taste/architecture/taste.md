# architecture
- Keep Swift files under ~250 lines; split aggressively into focused files. Confidence: 0.80
- No Combine, no storyboards, no AppDelegate-heavy patterns. Confidence: 0.85
- SwiftData @Model classes must not add @Observable; @Query only valid inside SwiftUI Views. Confidence: 0.80
- SwiftData relationships must declare explicit deleteRule: @Relationship(deleteRule: .cascade, inverse: \.field). Confidence: 0.70
- Use PersistentIdentifier for cross-actor SwiftData communication; only stable after context.save(). Confidence: 0.70
- Use FetchDescriptor with relationshipKeyPathsForPrefetching and propertiesToFetch for query performance. Confidence: 0.70
