//
//  NotificationInboxView.swift
//  BookMate
//
//  Created by Codex on 6/29/26.
//

import SwiftUI

struct NotificationInboxView: View {
    @ObservedObject var viewModel: BookMateViewModel
    @ObservedObject var model: NotificationInboxViewModel
    let onClose: (() -> Void)?
    let onSelect: (AppNotificationItem) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var isShowingNotificationSettings = false


    private var unreadNotifications: [AppNotificationItem] {
        model.notifications.filter { !$0.isRead }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color("AppBackground")

                VStack(alignment: .leading, spacing: 18) {
                    header

                    Group {
                        if model.isLoading && model.notifications.isEmpty {
                            loadingState
                                .transition(.opacity)
                        } else if model.notifications.isEmpty {
                            emptyState
                                .transition(.opacity)
                        } else {
                            notificationList
                                .transition(.opacity)
                        }
                    }
                    .animation(.easeOut(duration: 0.18), value: model.isLoading)
                    .animation(.easeOut(duration: 0.18), value: model.notifications.count)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 24)
            }
            .appToast($model.toast)
            .sheet(isPresented: $isShowingNotificationSettings) {
                NotificationSettingsView(viewModel: viewModel)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text("알림")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color("TextPrimary"))

                Text(unreadNotifications.isEmpty ? "새 알림이 없어요." : "\(unreadNotifications.count)개의 새 알림이 있어요.")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color("TextSecondary"))
            }

            Spacer()

            Button {
                isShowingNotificationSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color("TextSecondary"))
                    .frame(width: 38, height: 38)
                    .background(Color("Surface").opacity(0.92), in: Circle())
            }
            .accessibilityLabel("알림 설정")

            Button {
                close()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color("TextSecondary"))
                    .frame(width: 38, height: 38)
                    .background(Color("Surface").opacity(0.92), in: Circle())
            }
            .accessibilityLabel("닫기")
        }
    }

    private var loadingState: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 12) {
                notificationPlaceholderRow
                notificationPlaceholderRow
                    .opacity(0.55)
            }
            .padding(.bottom, 18)
        }
        .disabled(true)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "bell")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(Color("Primary"))
                .frame(width: 58, height: 58)
                .background(Color("Primary").opacity(0.12), in: Circle())

            VStack(spacing: 5) {
                Text("도착한 알림이 없어요")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color("TextPrimary"))

                Text("방명록과 서재 소식이 생기면 여기에서 확인할 수 있어요.")
                    .font(.caption)
                    .foregroundStyle(Color("TextSecondary"))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var notificationPlaceholderRow: some View {
        HStack(alignment: .top, spacing: 13) {
            Circle()
                .fill(Color("Primary").opacity(0.1))
                .frame(width: 38, height: 38)
                .overlay {
                    Image(systemName: "bell")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color("Primary").opacity(0.35))
                }

            VStack(alignment: .leading, spacing: 10) {
                Capsule()
                    .fill(Color("TextSecondary").opacity(0.14))
                    .frame(width: 210, height: 17)

                Capsule()
                    .fill(Color("TextSecondary").opacity(0.1))
                    .frame(maxWidth: .infinity)
                    .frame(height: 13)

                Capsule()
                    .fill(Color("TextSecondary").opacity(0.08))
                    .frame(width: 120, height: 11)
            }
            .padding(.top, 2)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("Surface").opacity(0.9), in: RoundedRectangle(cornerRadius: ReadingStyle.cardRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: ReadingStyle.cardRadius, style: .continuous)
                .stroke(Color("Border").opacity(0.18), lineWidth: 1)
        }
    }

    private var notificationList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 12) {
                if !unreadNotifications.isEmpty {
                    markAllReadButton
                }

                ForEach(model.notifications) { notification in
                    notificationRow(notification)
                }
            }
            .padding(.bottom, 18)
        }
        .refreshable {
            await loadNotifications()
        }
    }

    private var markAllReadButton: some View {
        HStack {
            Spacer()

            Button {
                Task {
                    await markAllRead()
                }
            } label: {
                Text("모두 읽음")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color("TextSecondary"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color("Surface").opacity(0.85), in: Capsule())
            }
        }
    }

    private func notificationRow(_ notification: AppNotificationItem) -> some View {
        Button {
            Task {
                await open(notification)
            }
        } label: {
            HStack(alignment: .top, spacing: 13) {
                Image(systemName: iconName(for: notification))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color("Primary"))
                    .frame(width: 38, height: 38)
                    .background(Color("Primary").opacity(notification.isRead ? 0.08 : 0.15), in: Circle())

                VStack(alignment: .leading, spacing: 7) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(notification.title)
                            .font(.callout)
                            .fontWeight(notification.isRead ? .semibold : .bold)
                            .foregroundStyle(Color("TextPrimary"))
                            .lineLimit(2)

                        if !notification.isRead {
                            Circle()
                                .fill(Color("Primary"))
                                .frame(width: 7, height: 7)
                        }
                    }

                    Text(notification.body)
                        .font(.caption)
                        .foregroundStyle(Color("TextSecondary"))
                        .lineLimit(2)

                    Text(notification.createdAtText)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(Color("TextSecondary").opacity(0.72))
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 15)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color("Surface").opacity(notification.isRead ? 0.82 : 0.96), in: RoundedRectangle(cornerRadius: ReadingStyle.cardRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: ReadingStyle.cardRadius, style: .continuous)
                    .stroke(Color("Border").opacity(notification.isRead ? 0.18 : 0.32), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    private func iconName(for notification: AppNotificationItem) -> String {
        switch notification.type {
        case "guestbook_message":
            return "text.bubble"
        default:
            return "bell"
        }
    }

    private func loadNotifications() async { await model.loadNotifications() }
    private func markAllRead() async { await model.markAllRead() }
    private func open(_ notification: AppNotificationItem) async {
        if await model.markRead(notification) {
            close()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { onSelect(notification) }
        }
    }

    private func close() {
        if let onClose {
            onClose()
        } else {
            dismiss()
        }
    }
}

#Preview {
    NotificationInboxView(
        viewModel: BookMateViewModel(),
        model: NotificationInboxViewModel(repository: NotificationAPIService(), context: AppContext()),
        onClose: nil
    ) { _ in }
}
