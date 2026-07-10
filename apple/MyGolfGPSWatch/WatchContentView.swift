import SwiftUI

struct WatchContentView: View {
    @EnvironmentObject var session: WatchSession
    @FocusState private var crownFocused: Bool

    var body: some View {
        Group {
            if session.isRoundActive {
                roundView
            } else if session.course != nil {
                startView
            } else {
                waitingView
            }
        }
        .focusable(session.isRoundActive)
        .digitalCrownRotation(
            Binding(
                get: { Double(session.currentHole) },
                set: { session.currentHole = min(18, max(1, Int($0.rounded()))) }
            ),
            from: 1,
            through: 18,
            by: 1,
            sensitivity: .medium,
            isContinuous: false,
            isHapticFeedbackEnabled: true
        )
    }

    private var waitingView: some View {
        VStack(spacing: 8) {
            Image(systemName: "applewatch")
                .font(.title2)
            Text("Select a course\non iPhone")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
    }

    private var startView: some View {
        VStack(spacing: 12) {
            Text(session.course?.name ?? "")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)

            if let mapped = session.course?.mappedHoleCount {
                Text("\(mapped)/18 holes mapped")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Button("Start Round") {
                session.startRound()
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
        }
    }

    private var roundView: some View {
        VStack(spacing: 4) {
            Text("HOLE \(session.currentHole)")
                .font(.caption2)
                .foregroundStyle(.secondary)

            if let yards = session.yardsToGreen {
                Text("\(yards)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.5)
                Text("yds")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("—")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                Text(session.currentHoleData?.hasGreen == false ? "No green data" : session.locationStatus)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            HStack {
                Button { session.previousHole() } label: {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.plain)

                Text("\(session.currentHole) / 18")
                    .font(.caption2)

                Button { session.nextHole() } label: {
                    Image(systemName: "chevron.right")
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 4)
        }
    }
}
