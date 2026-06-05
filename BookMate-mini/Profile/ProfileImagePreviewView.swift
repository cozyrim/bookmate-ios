//
//  ProfileImagePreviewView.swift
//  BookMate-mini
//
//  Created by 한채림 on 6/3/26.
//

import SwiftUI
import UIKit

struct ProfileImagePreviewView: View {
    @Environment(\.dismiss) private var dismiss
    
    let imageURLString: String?
    let fallbackImageName: String
    
    var body: some View {
        ZStack {
                    Color.black.opacity(0.94)
                        .ignoresSafeArea()

                    VStack {
                        HStack {
                            Spacer()

                            CircleIconButton(systemName: "xmark") {
                                dismiss()
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 20)

                        Spacer()

                        previewImage
                            .frame(maxWidth: 320, maxHeight: 420)
                            .clipShape(RoundedRectangle(cornerRadius: 32))
                            .shadow(color: Color("Shadow").opacity(0.35), radius: 18, x: 0, y: 10)

                        Spacer()
                    }
                }
    }
    @ViewBuilder
        private var previewImage: some View {
            if let imageURLString,
               let url = URL(string: imageURLString),
               url.isFileURL,
               let uiImage = UIImage(contentsOfFile: url.path) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
            } else if let imageURLString,
                      let url = URL(string: imageURLString),
                      imageURLString.hasPrefix("http") {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                    default:
                        Image(fallbackImageName)
                            .resizable()
                            .scaledToFit()
                    }
                }
            } else {
                Image(fallbackImageName)
                    .resizable()
                    .scaledToFit()
            }
        }
}

#Preview {
    ProfileImagePreviewView(
            imageURLString: nil,
            fallbackImageName: "profileImage"
        )
}
