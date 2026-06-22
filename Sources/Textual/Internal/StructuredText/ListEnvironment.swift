import SwiftUI

private struct ListItemSpacingKey: EnvironmentKey {
  static let defaultValue: FontScaled<StructuredText.BlockSpacing> = .fontScaled(top: 0.25)
}

private struct ResolvedListItemSpacingKey: EnvironmentKey {
  static let defaultValue: StructuredText.BlockSpacing = .init()
}

private struct ListItemSpacingEnabledKey: EnvironmentKey {
  static let defaultValue: Bool = false
}

extension EnvironmentValues {
  var listItemSpacing: FontScaled<StructuredText.BlockSpacing> {
    get { self[ListItemSpacingKey.self] }
    set { self[ListItemSpacingKey.self] = newValue }
  }

  var resolvedListItemSpacing: StructuredText.BlockSpacing {
    get { self[ResolvedListItemSpacingKey.self] }
    set { self[ResolvedListItemSpacingKey.self] = newValue }
  }

  var listItemSpacingEnabled: Bool {
    get { self[ListItemSpacingEnabledKey.self] }
    set { self[ListItemSpacingEnabledKey.self] = newValue }
  }
}
