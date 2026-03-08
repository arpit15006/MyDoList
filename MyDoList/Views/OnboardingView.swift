import SwiftData
import SwiftUI
import UserNotifications

struct OnboardingView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var selectedPage = 0

    var body: some View {
        TabView(selection: $selectedPage) {

            // PAGE 1: Welcome
            VStack {
                Spacer()
                    .frame(height: 40)

                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [.blue, .cyan], startPoint: .topLeading,
                                endPoint: .bottomTrailing)
                        )
                        .frame(width: 80, height: 80)
                        .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)

                    Image(systemName: "checkmark.list")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.bottom, 24)

                Text("Welcome to\nMyDoList")
                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .padding(.horizontal)
                    .padding(.bottom, 8)

                Text(
                    "The most beautiful way to manage your tasks, lists, and time natively on iOS."
                )
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 32)
                .padding(.bottom, 48)

                VStack(alignment: .leading, spacing: 28) {
                    FeatureRow(
                        icon: "list.bullet.rectangle.portrait", color: .indigo,
                        title: "Smart Lists",
                        description: "Organize your life into vibrant, beautiful categories.")
                    FeatureRow(
                        icon: "square.and.arrow.up", color: .green,
                        title: "Data Export",
                        description: "Seamlessly export all your data and notes securely offline.")
                    FeatureRow(
                        icon: "moon.stars.fill", color: .purple,
                        title: "Dark Mode",
                        description: "Fully supports system dark mode for deep-focus nights.")
                }
                .padding(.horizontal, 32)

                Spacer()

                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        selectedPage = 1
                    }
                    appViewModel.triggerHaptic(.light)
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .cornerRadius(16)
                        .padding(.horizontal, 32)
                }
                .padding(.bottom, 40)
            }
            .tag(0)

            // PAGE 2: Notifications
            VStack {
                Spacer()
                    .frame(height: 60)

                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [.orange, .red], startPoint: .topLeading,
                                endPoint: .bottomTrailing)
                        )
                        .frame(width: 80, height: 80)
                        .shadow(color: .orange.opacity(0.3), radius: 10, x: 0, y: 5)

                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.bottom, 24)

                Text("Never Miss a\nDeadline")
                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .padding(.horizontal)
                    .padding(.bottom, 8)

                Text(
                    "Get timely reminders for tasks with due dates. You can always change this later in Settings."
                )
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 32)

                Spacer()

                VStack(spacing: 16) {
                    Button {
                        NotificationManager.shared.requestAuthorization()
                    } label: {
                        Text("Enable Notifications")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.orange)
                            .cornerRadius(16)
                            .padding(.horizontal, 32)
                    }

                    Button {
                        appViewModel.hasSeenOnboarding = true
                        appViewModel.triggerHaptic(.medium)
                    } label: {
                        Text("Get Started")
                            .font(.headline)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(16)
                            .padding(.horizontal, 32)
                    }
                }
                .padding(.bottom, 40)
            }
            .tag(1)

        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .background(Color(.systemBackground).ignoresSafeArea())
    }
}

struct FeatureRow: View {
    let icon: String
    let color: Color
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(color.opacity(0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppViewModel())
}
