import Combine
import SwiftData
import SwiftUI
import UserNotifications

@MainActor
class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    @Published var isAuthorized = false

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        checkAuthorization()
    }

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) {
            success, error in
            DispatchQueue.main.async {
                self.isAuthorized = success
                if let error = error {
                    print("Notification Authorization Error: \(error.localizedDescription)")
                }
            }
        }
    }

    func checkAuthorization() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    func scheduleNotification(for task: MyDoList.Task) {
        guard isAuthorized, let dueDate = task.dueDate, !task.isCompleted else {
            removeNotification(for: task)
            return
        }

        // Remove any existing notification first
        removeNotification(for: task)

        // Ensure the due date is in the future
        guard dueDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Task Due"
        content.body = task.title
        content.sound = .default

        if let listTitle = task.list?.title {
            content.subtitle = listTitle
        }

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute], from: dueDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: task.persistentModelID.hashValue.description,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }

    func removeNotification(for task: MyDoList.Task) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
            task.persistentModelID.hashValue.description
        ])
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler:
            @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
}
