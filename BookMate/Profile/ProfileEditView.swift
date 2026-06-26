//
//  ProfileEditView.swift
//  BookMate
//
//  Created by 한채림 on 6/2/26.
//

import SwiftUI
import PhotosUI

struct ProfileEditView: View {
    @ObservedObject var authViewModel: AuthSessionViewModel
    var onSaveComplete: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    @State private var nickname = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedProfileImage: UIImage?
    @State private var profileImageUrlToSave: String?
    @State private var isPublicToSave: Bool = true
    @State private var isCheckingNickname = false
    @State private var isUploadingProfileImage = false
    @State private var profileImageUploadRequestID: UUID?
    @State private var nicknameAvailability: NicknameAvailabilityResponse?
    @FocusState private var isNicknameFocused: Bool

    private var currentNickname: String {
        authViewModel.profile?.nickname
        ?? authViewModel.currentUser?.nickname
        ?? ""
    }

    private var currentProfileImageUrl: String? {
        authViewModel.profile?.profileImageUrl
        ?? authViewModel.currentUser?.profileImageUrl
    }

    private var normalizedNickname: String {
        AuthValidation.normalizedNickname(nickname)
    }

    private var isNicknameChanged: Bool {
        normalizedNickname != currentNickname
    }

    private var isNicknameCheckedAndAvailable: Bool {
        nicknameAvailability?.available == true &&
        nicknameAvailability?.nickname == normalizedNickname
    }

    private var hasCustomProfileImage: Bool {
        selectedProfileImage != nil || !(profileImageUrlToSave?.isEmpty ?? true)
    }

    private var canSave: Bool {
        guard !isUploadingProfileImage else { return false }
        guard AuthValidation.isValidNickname(nickname) else { return false }
        return !isNicknameChanged || isNicknameCheckedAndAvailable
    }

    private var saveButtonTitle: String {
        if authViewModel.isLoading { return "저장 중..." }
        if isUploadingProfileImage { return "업로드 중..." }
        return "저장하기"
    }

    private var nicknameHelperText: String {
        if !isNicknameChanged,
           AuthValidation.isValidNickname(nickname) {
            return "현재 사용 중인 닉네임이에요."
        }

        if let nicknameAvailability,
           nicknameAvailability.nickname == normalizedNickname {
            return nicknameAvailability.message
        }

        return AuthValidation.nicknameHelperText(nickname)
    }

    private var nicknameHelperColor: Color {
        if nickname.isEmpty {
            return Color("TextSecondary").opacity(0.78)
        }

        if !isNicknameChanged,
           AuthValidation.isValidNickname(nickname) {
            return Color("TextSecondary").opacity(0.78)
        }

        if let nicknameAvailability,
           nicknameAvailability.nickname == normalizedNickname {
            return nicknameAvailability.available ? Color("PrimaryDeep") : Color("Error")
        }

        return AuthValidation.isValidNickname(nickname) ? Color("TextSecondary").opacity(0.78) : Color("Error")
    }

    var body: some View {
        ZStack {
            Color("AppBackground")
                .ignoresSafeArea()
                .onTapGesture {
                    isNicknameFocused = false
                }

            VStack(spacing: 24) {
                SettingsScreenHeader(title: "프로필 수정")

                VStack(spacing: 18) {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        ProfileImageView(
                            imageName: "profileImage",
                            imageURLString: profileImageUrlToSave,
                            selectedImage: selectedProfileImage,
                            showsEditIcon: true
                        )
                    }
                    .buttonStyle(.plain)
                    .onChange(of: selectedPhotoItem) { _, newItem in
                        Task {
                            let requestID = UUID()
                            profileImageUploadRequestID = requestID
                            isUploadingProfileImage = true

                            defer {
                                if profileImageUploadRequestID == requestID {
                                    isUploadingProfileImage = false
                                }
                            }

                            guard let data = try? await newItem?.loadTransferable(type: Data.self),
                                  let image = UIImage(data: data),
                                  let jpegData = image.jpegData(compressionQuality: 0.85) else {
                                return
                            }

                            guard profileImageUploadRequestID == requestID else { return }
                            selectedProfileImage = image

                            if let uploadedUrl = await authViewModel.uploadProfileImage(imageData: jpegData) {
                                guard profileImageUploadRequestID == requestID else { return }
                                profileImageUrlToSave = uploadedUrl
                            } else if profileImageUploadRequestID == requestID {
                                selectedPhotoItem = nil
                                selectedProfileImage = nil
                            }
                        }
                    }

                    Button {
                        resetProfileImageToDefault()
                    } label: {
                        Label("기본 이미지로 변경", systemImage: "arrow.counterclockwise")
                            .font(.caption.bold())
                            .foregroundStyle(Color("PrimaryDeep"))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(Color("Primary").opacity(0.14), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(!hasCustomProfileImage)
                    .opacity(hasCustomProfileImage ? 1 : 0.45)
                    .accessibilityHint("프로필 이미지를 기본 이미지로 되돌립니다.")

                    nicknameEditor

                    Toggle("내 책장 공개 여부", isOn: $isPublicToSave)
                        .font(.callout)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color("TextPrimary"))
                        .tint(Color("Primary"))
                        .padding(.vertical, 8)
                }
                .padding(.horizontal, 28)

                Spacer()

                SettingsPrimaryButton(title: saveButtonTitle) {
                    saveProfile()
                }
                .disabled(!canSave || authViewModel.isLoading)
                .opacity(canSave ? 1 : 0.55)
                .padding(.horizontal, 28)
                .padding(.bottom, 24)
            }
        }
        .navigationBarBackButtonHidden(true)
        .enableSwipeBackGesture()
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            nickname = currentNickname
            profileImageUrlToSave = currentProfileImageUrl
            isPublicToSave = authViewModel.profile?.isPublic ?? true
        }
        .onChange(of: nickname) { _, newValue in
            let normalized = AuthValidation.normalizedNickname(newValue)
            if nicknameAvailability?.nickname != normalized {
                nicknameAvailability = nil
            }
        }
    }

    private var nicknameEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("닉네임")
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundStyle(Color("TextSecondary"))

            HStack(spacing: 12) {
                TextField("닉네임을 입력하세요", text: $nickname)
                    .textInputAutocapitalization(.never)
                    .focused($isNicknameFocused)

                Button {
                    Task {
                        await checkNicknameAvailability()
                    }
                } label: {
                    HStack(spacing: 5) {
                        if isCheckingNickname {
                            ProgressView()
                                .tint(Color("PrimaryDeep"))
                                .scaleEffect(0.72)
                        }

                        Text(isCheckingNickname ? "확인 중" : "중복확인")
                    }
                    .font(.caption.bold())
                    .foregroundStyle(Color("PrimaryDeep"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color("Primary").opacity(0.18), in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(!isNicknameChanged || !AuthValidation.isValidNickname(nickname) || isCheckingNickname)
                .opacity(isNicknameChanged && AuthValidation.isValidNickname(nickname) ? 1 : 0.45)
            }
            .padding(.horizontal, 18)
            .frame(height: 58)
            .background(Color("Surface").opacity(0.88))
            .clipShape(RoundedRectangle(cornerRadius: 18))

            Text(nicknameHelperText)
                .font(.caption2)
                .foregroundStyle(nicknameHelperColor)
                .padding(.horizontal, 4)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func saveProfile() {
        guard canSave else { return }

        Task {
            let success = await authViewModel.updateProfile(
                nickname: normalizedNickname,
                profileImageUrl: profileImageUrlToSave,
                isPublic: isPublicToSave
            )

            if success {
                onSaveComplete?()
                dismiss()
            }
        }
    }

    private func resetProfileImageToDefault() {
        isNicknameFocused = false
        isUploadingProfileImage = false
        profileImageUploadRequestID = nil
        selectedPhotoItem = nil
        selectedProfileImage = nil
        profileImageUrlToSave = nil
    }

    private func checkNicknameAvailability() async {
        let nicknameToCheck = normalizedNickname
        guard isNicknameChanged,
              AuthValidation.isValidNickname(nicknameToCheck),
              !isCheckingNickname else { return }

        isNicknameFocused = false
        isCheckingNickname = true
        nicknameAvailability = await authViewModel.checkNicknameAvailability(nickname: nicknameToCheck)
        isCheckingNickname = false
    }

    private func saveProfileImageToDocuments(_ image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.85) else {
            return nil
        }

        let fileName = "profile-\(UUID().uuidString).jpg"
        let documentsURL = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]

        let fileURL = documentsURL.appendingPathComponent(fileName)

        do {
            try data.write(to: fileURL)
            return fileURL.absoluteString
        } catch {
            DebugLogger.log("프로필 이미지 저장 실패:", error)
            return nil
        }
    }
}

#Preview {
    ProfileEditView(authViewModel: AuthSessionViewModel())
}
