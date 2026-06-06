//
//  ProfileEditView.swift
//  BookMate-mini
//
//  Created by 한채림 on 6/2/26.
//

import SwiftUI
import PhotosUI

struct ProfileEditView: View {
    @ObservedObject var authViewModel: AuthSessionViewModel
        @Environment(\.dismiss) private var dismiss

        @State private var nickname = ""
        @State private var selectedPhotoItem: PhotosPickerItem?
        @State private var selectedProfileImage: UIImage?
        @State private var profileImageUrlToSave: String?

    
    private var currentNickname: String {
        authViewModel.profile?.nickname
        ?? authViewModel.currentUser?.nickname
        ?? ""
    }
    
    private var currentProfileImageUrl: String? {
        authViewModel.profile?.profileImageUrl
        ?? authViewModel.currentUser?.profileImageUrl
    }

    var body: some View {
        ZStack {
                    Color("AppBackground")
                        .ignoresSafeArea()
            
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
                                        guard let data = try? await newItem?.loadTransferable(type: Data.self),
                                              let image = UIImage(data: data),
                                              let jpegData = image.jpegData(compressionQuality: 0.85) else {
                                            return
                                        }

                                        selectedProfileImage = image
                                        
                                        if let uploadedUrl = await authViewModel.uploadProfileImage(imageData: jpegData) {
                                            profileImageUrlToSave = uploadedUrl
                                        }
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 10) {
                                                        Text("닉네임")
                                                            .font(.callout)
                                                            .fontWeight(.semibold)
                                                            .foregroundStyle(Color("TextSecondary"))

                                                        TextField("닉네임을 입력하세요", text: $nickname)
                                                            .padding(.horizontal, 18)
                                                            .frame(height: 58)
                                                            .background(Color("Surface").opacity(0.88))
                                                            .clipShape(RoundedRectangle(cornerRadius: 18))
                                                    }
                                                }
                            .padding(.horizontal, 28)

                                            Spacer()

                                            SettingsPrimaryButton(title: authViewModel.isLoading ? "저장 중..." : "저장하기") {
                                                saveProfile()
                                            }
                                            .disabled(nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                            .padding(.horizontal, 28)
                                            .padding(.bottom, 24)
                                        }
                                    }
        .navigationBarBackButtonHidden(true)
                .toolbar(.hidden, for: .tabBar)
                .onAppear {
                    nickname = currentNickname
                    profileImageUrlToSave = currentProfileImageUrl
                }
            }
    
    private func saveProfile() {
        let trimmedNickname = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedNickname.isEmpty else { return }
            
        Task {
            let success = await authViewModel.updateProfile(nickname: trimmedNickname, profileImageUrl: profileImageUrlToSave)
            
            if success {
                dismiss()
            }
        }
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
