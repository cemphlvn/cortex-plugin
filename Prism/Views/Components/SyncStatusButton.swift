import SwiftUI

/// Tappable sync status indicator with popover details.
/// Shows cloud icon + badge, tappable for status popover with manual sync option.
/// If user doesn't have Plus, shows lock and triggers paywall on tap.
struct SyncStatusButton: View {
    let status: SyncStatus
    let isAuthenticated: Bool
    let pendingCount: Int
    var hasPro: Bool = true
    let onSync: () async -> Void

    @State private var showPopover = false
    @State private var isSyncing = false

    private var isError: Bool {
        if case .error = status { return true }
        return false
    }

    /// If authenticated but no Plus, show locked state
    private var isLocked: Bool {
        isAuthenticated && !hasPro
    }

    private var icon: String {
        if !isAuthenticated {
            return "icloud.slash"
        }
        if isLocked {
            return "lock.icloud"
        }
        switch status {
        case .idle:
            return pendingCount > 0 ? "icloud.and.arrow.up" : "checkmark.icloud"
        case .syncing:
            return "arrow.triangle.2.circlepath.icloud"
        case .synced:
            return "checkmark.icloud"
        case .pendingSync:
            return "icloud.and.arrow.up"
        case .error:
            return "exclamationmark.icloud"
        case .offline:
            return "icloud.slash"
        }
    }

    private var iconColor: Color {
        if !isAuthenticated {
            return PrismTheme.textTertiary
        }
        if isLocked {
            return .orange
        }
        switch status {
        case .idle:
            return pendingCount > 0 ? .orange : .green.opacity(0.8)
        case .syncing:
            return .cyan
        case .synced:
            return .green
        case .pendingSync:
            return .orange
        case .error:
            return .red
        case .offline:
            return PrismTheme.textTertiary
        }
    }

    private var statusText: String {
        if !isAuthenticated {
            return "Sign in to sync"
        }
        if isLocked {
            return "Sync locked"
        }
        switch status {
        case .idle:
            return pendingCount > 0 ? "\(pendingCount) waiting" : "Synced"
        case .syncing:
            return "Syncing..."
        case .synced:
            return "Synced"
        case .pendingSync(let count):
            return "\(count) waiting"
        case .error(let msg):
            return msg
        case .offline:
            return "Offline"
        }
    }

    private var detailText: String {
        if !isAuthenticated {
            return "Your prisms are stored locally. Sign in to back them up to the cloud."
        }
        if isLocked {
            return "Upgrade to Prism Pro to sync your prisms across devices."
        }
        switch status {
        case .idle where pendingCount > 0:
            return "\(pendingCount) prism(s) waiting to sync. Tap to sync now."
        case .idle:
            return "All prisms are backed up."
        case .syncing:
            return "Uploading changes..."
        case .synced:
            return "All changes saved to cloud."
        case .pendingSync(let count):
            return "\(count) prism(s) waiting. Tap to sync now."
        case .error:
            return "Tap to retry sync."
        case .offline:
            return "Changes will sync when online."
        }
    }

    var body: some View {
        Button {
            showPopover = true
        } label: {
            HStack(spacing: 4) {
                if case .syncing = status {
                    ProgressView()
                        .scaleEffect(0.6)
                        .tint(iconColor)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(iconColor)
                }

                if pendingCount > 0 && isAuthenticated {
                    Text("\(pendingCount)")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Capsule().fill(.orange))
                }
            }
            .frame(minWidth: 28, minHeight: 28)
        }
        .popover(isPresented: $showPopover) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(iconColor)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(statusText)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(PrismTheme.textPrimary)

                        Text(detailText)
                            .font(.caption)
                            .foregroundStyle(PrismTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                // Action button
                if isAuthenticated {
                    Divider()

                    if isLocked {
                        // Upgrade button for locked state
                        Button {
                            showPopover = false
                            Task { await onSync() }
                        } label: {
                            HStack {
                                Image(systemName: "sparkles")
                                Text("Upgrade to Prism Pro")
                            }
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(Color.orange))
                        }
                    } else if pendingCount > 0 || isError {
                        // Sync button
                        Button {
                            isSyncing = true
                            Task {
                                await onSync()
                                isSyncing = false
                                showPopover = false
                            }
                        } label: {
                            HStack {
                                if isSyncing {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                        .tint(.white)
                                } else {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                }
                                Text(isSyncing ? "Syncing..." : "Sync Now")
                            }
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(Color.accentColor))
                        }
                        .disabled(isSyncing)
                    }
                }
            }
            .padding()
            .frame(width: 260)
            .background(PrismTheme.surface)
            .presentationCompactAdaptation(.popover)
        }
        .animation(.easeInOut(duration: 0.2), value: status)
        .animation(.easeInOut(duration: 0.2), value: isAuthenticated)
    }
}

#Preview("Synced") {
    SyncStatusButton(
        status: .idle,
        isAuthenticated: true,
        pendingCount: 0,
        onSync: {}
    )
    .padding()
    .background(PrismTheme.background)
}

#Preview("Pending") {
    SyncStatusButton(
        status: .pendingSync(count: 3),
        isAuthenticated: true,
        pendingCount: 3,
        onSync: {}
    )
    .padding()
    .background(PrismTheme.background)
}

#Preview("Not Signed In") {
    SyncStatusButton(
        status: .idle,
        isAuthenticated: false,
        pendingCount: 2,
        onSync: {}
    )
    .padding()
    .background(PrismTheme.background)
}
