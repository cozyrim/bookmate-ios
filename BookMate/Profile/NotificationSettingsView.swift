//
//  NotificationsSettingsView.swift
//  BookMate
//
//  Created by 한채림 on 6/2/26.
//

import SwiftUI
import UIKit

struct NotificationSettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage("readingReminderEnabled") private var readingReminderEnabled = true
    @AppStorage("readingReminderHour") private var readingReminderHour = 21
    @AppStorage("readingReminderMinute") private var readingReminderMinute = 0

    @AppStorage("readingRecordReminderEnabled") private var readingRecordReminderEnabled = true
    @AppStorage("readingRecordReminderDays") private var readingRecordReminderDays = 3

    @State private var isShowingPermissionAlert = false


    private var reminderTime: Binding<Date> {
        Binding {
            var components = DateComponents()
            components.hour = readingReminderHour
            components.minute = readingReminderMinute
            return Calendar.current.date(from: components) ?? Date()
        } set: { newValue in
            let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            readingReminderHour = components.hour ?? 21
            readingReminderMinute = components.minute ?? 0
        }
    }

    var body: some View {
        ZStack {
            Color("AppBackground")
                .ignoresSafeArea()

            VStack(spacing: 24) {
                SettingsScreenHeader(title: "알림 설정")

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                                            SettingsSectionCard(title: "독서 리마인드") {
                                                SettingsToggleRow(
                                                    iconName: "bell",
                                                    title: "독서 알림 받기",
                                                    subtitle: "책 읽는 시간을 부드럽게 알려드려요.",
                                                    isOn: $readingReminderEnabled
                                                )

                            if readingReminderEnabled {
                                SettingsDivider()

                                HStack(spacing: 16) {
                                    Image(systemName: "clock")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundStyle(Color("PrimaryDeep"))
                                        .frame(width: 44, height: 44)
                                        .background(Color("Primary").opacity(0.16))
                                        .clipShape(Circle())

                                    Text("알림 시간")
                                        .font(.callout)
                                        .fontWeight(.semibold)

                                    Spacer()

                                    DatePicker("", selection: reminderTime, displayedComponents: .hourAndMinute)
                                        .labelsHidden()
                                }
                                .padding(.horizontal, 20)
                                .frame(minHeight: 72)
                            }
                        }
                        SettingsSectionCard(title: "책 읽기 기록 알림") {
                            SettingsToggleRow(
                                iconName: "book",
                                title: "기록 리마인드",
                                subtitle: "며칠 동안 독서 기록이 없으면 알려드려요.",
                                isOn: $readingRecordReminderEnabled
                            )

                            if readingRecordReminderEnabled {
                                SettingsDivider()

                                HStack(spacing: 16) {
                                    Image(systemName: "calendar.badge.clock")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundStyle(Color("PrimaryDeep"))
                                        .frame(width: 44, height: 44)
                                        .background(Color("Primary").opacity(0.16))
                                        .clipShape(Circle())

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("기준일 설정")
                                            .font(.callout)
                                            .fontWeight(.semibold)

                                        Text("\(readingRecordReminderDays)일 동안 기록이 없을 때")
                                            .font(.caption)
                                            .foregroundStyle(Color("TextSecondary").opacity(0.75))
                                    }

                                    Spacer()

                                    Stepper("", value: $readingRecordReminderDays, in: 1...14)
                                        .labelsHidden()
                                }
                                .padding(.horizontal, 20)
                                .frame(minHeight: 78)
                            }
                        }
                        SettingsPrimaryButton(title: "저장하기") {
                            Task {
                                guard readingReminderEnabled || readingRecordReminderEnabled else {
                                    ReadingNotificationService.shared.cancelAllReadingReminders()
                                    dismiss()
                                    return
                                }

                                let granted = await ReadingNotificationService.shared.requestAuthorization()

                                guard granted else {
                                    isShowingPermissionAlert = true
                                    return
                                }

                                if readingReminderEnabled {
                                    await ReadingNotificationService.shared.scheduleDailyReadingReminder(
                                        hour: readingReminderHour,
                                        minute: readingReminderMinute
                                    )
                                } else {
                                    ReadingNotificationService.shared.cancelDailyReadingReminder()
                                }

                                if readingRecordReminderEnabled {
                                    await ReadingNotificationService.shared.scheduleReadingRecordReminder(
                                        afterDays: readingRecordReminderDays
                                    )
                                } else {
                                    ReadingNotificationService.shared.cancelReadingRecordReminder()
                                }

                                dismiss()
                            }
                        }
                        .padding(.top, 16)
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .alert("알림 권한이 꺼져 있어요", isPresented: $isShowingPermissionAlert) {
            Button("취소", role: .cancel) { }

            Button("설정으로 이동") {
                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                UIApplication.shared.open(url)
            }
        } message: {
            Text("알림을 받으려면 iPhone 설정에서 BookMate 알림 권한을 켜주세요.")
        }




    }
}
#Preview {
    NotificationSettingsView()
}
